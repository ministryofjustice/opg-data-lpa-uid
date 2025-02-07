package main

import (
	"context"
	"errors"
	"log/slog"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

var (
	ErrMetadataChanged = errors.New("metadata has been changed")
	ErrUidExists       = errors.New("uid already exists")
)

type LpaType string

const (
	LpaTypePersonalWelfare    LpaType = "personal-welfare"
	LpaTypePropertyAndAffairs LpaType = "property-and-affairs"
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

type Lpa struct {
	UID       string    `dynamodbav:"uid"`
	CreatedAt time.Time `dynamodbav:"created_at"`
	Type      LpaType   `dynamodbav:"type"`
	Source    LpaSource `dynamodbav:"source"`
	Donor     Donor     `dynamodbav:"donor"`
}

func (l *Lambda) getMaximum(ctx context.Context) (int, error) {
	output, err := l.dynamo.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(l.tableName),
		Key: map[string]types.AttributeValue{
			"uid": &types.AttributeValueMemberS{Value: "#METADATA"},
		},
		AttributesToGet: []string{"Maximum"},
		ConsistentRead:  aws.Bool(true),
	})
	if err != nil {
		return 0, err
	}
	if output.Item == nil {
		return 0, nil
	}

	var max int
	if err := attributevalue.Unmarshal(output.Item["Maximum"], &max); err != nil {
		return 0, err
	}

	return max, nil
}

func (l *Lambda) insertLpa(ctx context.Context, currentMaximum int, req Request) error {
	nextUID := formatUID(currentMaximum + 1)

	lpa := Lpa{
		UID:       nextUID,
		CreatedAt: l.now(),
		Type:      req.Type,
		Source:    req.Source,
		Donor:     req.Donor,
	}

	marshalled, err := attributevalue.MarshalMap(lpa)
	if err != nil {
		return err
	}

	transaction := &dynamodb.TransactWriteItemsInput{
		TransactItems: []types.TransactWriteItem{
			{
				Update: &types.Update{
					TableName: aws.String(l.tableName),
					Key: map[string]types.AttributeValue{
						"uid": &types.AttributeValueMemberS{Value: "#METADATA"},
					},
					ConditionExpression: aws.String("Maximum = :currentMaximum"),
					UpdateExpression:    aws.String("SET Maximum = :nextMaximum"),
					ExpressionAttributeValues: map[string]types.AttributeValue{
						":currentMaximum": &types.AttributeValueMemberN{Value: strconv.Itoa(currentMaximum)},
						":nextMaximum":    &types.AttributeValueMemberN{Value: strconv.Itoa(currentMaximum + 1)},
					},
				},
			},
			{
				Put: &types.Put{
					TableName:           aws.String(l.tableName),
					Item:                marshalled,
					ConditionExpression: aws.String("attribute_not_exists(uid)"),
				},
			},
		},
	}

	if currentMaximum == 0 {
		l.logger.DebugContext(ctx, "inserting metadata", slog.Any("max", currentMaximum+1))
		transaction.TransactItems[0] = types.TransactWriteItem{
			Put: &types.Put{
				TableName: aws.String(l.tableName),
				Item: map[string]types.AttributeValue{
					"uid":     &types.AttributeValueMemberS{Value: "#METADATA"},
					"Maximum": &types.AttributeValueMemberN{Value: strconv.Itoa(currentMaximum + 1)},
				},
				ConditionExpression: aws.String("attribute_not_exists(uid)"),
			},
		}
	}

	_, err = l.dynamo.TransactWriteItems(ctx, transaction)

	var tce *types.TransactionCanceledException
	if errors.As(err, &tce) {
		if *tce.CancellationReasons[0].Code == "ConditionalCheckFailed" {
			return ErrMetadataChanged
		}

		if *tce.CancellationReasons[1].Code == "ConditionalCheckFailed" {
			return ErrUidExists
		}
	}

	return err
}
