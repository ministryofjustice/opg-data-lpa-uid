package main

import (
	"encoding/json"
	"log"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbiface"
)

type LpaType string

const (
	LpaTypeHealthAndWelfare   LpaType = "hw"
	LpaTypePersonalAndFinance LpaType = "pfa"
)

type LpaSource string

const (
	LpaSourceApplicant LpaSource = "APPLICANT"
	LpaSourcePhone     LpaSource = "PHONE"
)

type Donor struct {
	Name        string `json:"name" dynamodbav:"name"`
	DateOfBirth string `json:"dob" dynamodbav:"dob"`
	Postcode    string `json:"postcode" dynamodbav:"postcode"`
}

type Request struct {
	Type      LpaType   `json:"type" dynamodbav:"type"`
	Source    LpaSource `json:"source" dynamodbav:"source"`
	Donor     Donor     `json:"donor" dynamodbav:"donor"`
	CreatedAt time.Time `json:"-" dynamodbav:"created_at"`
	Uid       string    `json:"-" dynamodbav:"uid"`
}

type Response struct {
	Uid string `json:"uid"`
}

type Lambda struct {
	ddb       dynamodbiface.DynamoDBAPI
	tableName string
}

func (l *Lambda) HandleEvent(event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var data Request
	err := json.Unmarshal([]byte(event.Body), &data)

	if err != nil {
		log.Print(err)
		return ProblemInvalidRequest.Respond()
	}

	// validate
	if isValid, validationErrors := validate(data); isValid {
		problem := ProblemInvalidRequest
		problem.Errors = validationErrors

		return problem.Respond()
	}

	// generate uid
	data.CreatedAt = time.Now()
	data.Uid, err = generateUID()

	if err != nil {
		log.Print(err)
		return ProblemInternalServerError.Respond()
	}

	// save to dynamodb
	item, err := dynamodbattribute.MarshalMap(data)
	if err != nil {
		log.Print(err)
		return ProblemInternalServerError.Respond()
	}

	_, err = l.ddb.PutItem(&dynamodb.PutItemInput{
		TableName: aws.String(l.tableName),
		Item:      item,
	})

	if err != nil {
		log.Print(err)
		return ProblemInternalServerError.Respond()
	}

	// respond
	response := Response{Uid: hyphenateUID(data.Uid)}

	body, err := json.Marshal(response)

	if err != nil {
		log.Print(err)
		return ProblemInternalServerError.Respond()
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       string(body),
	}, nil
}

func hyphenateUID(uid string) string {
	offset := len(UID_PREFIX)

	return uid[0:offset] + uid[offset:offset+4] + "-" + uid[offset+4:offset+8] + "-" + uid[offset+8:]
}

func main() {
	sess := session.Must(session.NewSession())

	endpoint := os.Getenv("AWS_DYNAMODB_ENDPOINT")
	sess.Config.Endpoint = &endpoint

	l := &Lambda{
		ddb:       dynamodb.New(sess),
		tableName: os.Getenv("AWS_DYNAMODB_TABLE_NAME"),
	}

	lambda.Start(l.HandleEvent)
}