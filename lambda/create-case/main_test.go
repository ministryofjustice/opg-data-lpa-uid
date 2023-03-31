package main

import (
	"encoding/json"
	"testing"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type mockDynamoDB struct {
	*dynamodb.DynamoDB
	mock.Mock
}

func (m *mockDynamoDB) PutItem(input *dynamodb.PutItemInput) (*dynamodb.PutItemOutput, error) {
	args := m.Called(*input.TableName, input.Item)

	return &dynamodb.PutItemOutput{}, args.Error(0)
}

func generateProxyRequest(request Request) events.APIGatewayProxyRequest {
	encoded, _ := json.Marshal(request)

	return events.APIGatewayProxyRequest{
		Body: string(encoded),
	}
}

func TestHandleEventErrorIfBadBody(t *testing.T) {
	l := Lambda{}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: "bad body",
	})

	assert.Equal(t, 400, resp.StatusCode)
	assert.Nil(t, err)

	var problem Problem
	_ = json.Unmarshal([]byte(resp.Body), &problem)

	assert.Equal(t, "INVALID_REQUEST", problem.Code)
	assert.Equal(t, "Invalid request", problem.Detail)
}

func TestHandleEventErrorIfMissingRequiredFields(t *testing.T) {
	l := Lambda{}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: "{}",
	})

	assert.Equal(t, 400, resp.StatusCode)
	assert.Nil(t, err)

	var problem Problem
	_ = json.Unmarshal([]byte(resp.Body), &problem)

	assert.Equal(t, "INVALID_REQUEST", problem.Code)
	assert.Contains(t, problem.Errors, Error{
		Source: "/source",
		Detail: "required",
	})
	assert.Contains(t, problem.Errors, Error{
		Source: "/type",
		Detail: "required",
	})
	assert.Contains(t, problem.Errors, Error{
		Source: "/donor/name",
		Detail: "required",
	})
	assert.Contains(t, problem.Errors, Error{
		Source: "/donor/dob",
		Detail: "required",
	})
	assert.Contains(t, problem.Errors, Error{
		Source: "/donor/postcode",
		Detail: "required",
	})
}

func TestHandleEventErrorIfFieldsAreInvalid(t *testing.T) {
	l := Lambda{}

	resp, err := l.HandleEvent(generateProxyRequest(Request{
		Type:   "bad",
		Source: "bad",
		Donor: Donor{
			Name:        "some name",
			DateOfBirth: "27/06/1976",
			Postcode:    "bad",
		},
	}))

	assert.Equal(t, 400, resp.StatusCode)
	assert.Nil(t, err)

	var problem Problem
	_ = json.Unmarshal([]byte(resp.Body), &problem)

	assert.Equal(t, "INVALID_REQUEST", problem.Code)
	assert.Contains(t, problem.Errors, Error{
		Source: "/source",
		Detail: "must be APPLICANT or PHONE",
	})
	assert.Contains(t, problem.Errors, Error{
		Source: "/type",
		Detail: "must be hw or pfa",
	})
	assert.Contains(t, problem.Errors, Error{
		Source: "/donor/dob",
		Detail: "must match format YYYY-MM-DD",
	})
	assert.Contains(t, problem.Errors, Error{
		Source: "/donor/postcode",
		Detail: "must be a valid postcode",
	})
}

func TestHandleEventSuccess(t *testing.T) {
	mDdb := new(mockDynamoDB)
	l := Lambda{
		ddb:       mDdb,
		tableName: "my-table",
	}

	mDdb.On("PutItem", "my-table", mock.Anything).Return(nil)

	resp, err := l.HandleEvent(generateProxyRequest(Request{
		Type:   "hw",
		Source: "PHONE",
		Donor: Donor{
			Name:        "some name",
			DateOfBirth: "1976-06-27",
			Postcode:    "B7A 8FJ",
		},
	}))

	assert.Regexp(t, `^{"uid":"TMP-[a-z0-9]{6}"}$`, resp.Body)
	assert.Equal(t, 200, resp.StatusCode)
	assert.Nil(t, err)
}
