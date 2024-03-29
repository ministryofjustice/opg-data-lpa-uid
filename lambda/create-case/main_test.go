package main

import (
	"encoding/json"
	"errors"
	"github.com/aws/aws-sdk-go/aws"
	"regexp"
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

func (m *mockDynamoDB) GetItem(input *dynamodb.GetItemInput) (*dynamodb.GetItemOutput, error) {
	args := m.Called(*input.TableName, input.Key)

	if args.Get(0) != nil {
		return args.Get(0).(*dynamodb.GetItemOutput), args.Error(1)
	}
	return &dynamodb.GetItemOutput{}, args.Error(1)
}

func (m *mockDynamoDB) PutItem(input *dynamodb.PutItemInput) (*dynamodb.PutItemOutput, error) {
	args := m.Called(*input.TableName, input.Item)

	return &dynamodb.PutItemOutput{}, args.Error(0)
}

type mockLogger struct {
	mock.Mock
}

func (m *mockLogger) Print(content ...interface{}) {
	m.Called(content)
}

func generateProxyRequest(request Request) events.APIGatewayProxyRequest {
	encoded, _ := json.Marshal(request)

	return events.APIGatewayProxyRequest{
		Body: string(encoded),
	}
}

func TestHandleEventErrorIfBadBody(t *testing.T) {
	logger := &mockLogger{}
	logger.On("Print", mock.Anything)

	l := Lambda{
		logger: logger,
	}

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
		Detail: "must be personal-welfare or property-and-affairs",
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

	var reUid = regexp.MustCompile(`^M-[346789QWERTYUPADFGHJKLXCVBNM]{12}$`)

	mDdb.
		On("GetItem", "my-table", mock.MatchedBy(func(key map[string]*dynamodb.AttributeValue) bool {
			return reUid.MatchString(*key["uid"].S)
		})).
		Return(&dynamodb.GetItemOutput{}, nil)

	mDdb.
		On("PutItem", "my-table", mock.MatchedBy(func(item map[string]*dynamodb.AttributeValue) bool {
			return reUid.MatchString(*item["uid"].S) &&
				validateChecksum((*item["uid"].S)[2:]) &&
				*item["source"].S == "PHONE" &&
				*item["type"].S == "personal-welfare" &&
				*item["donor"].M["name"].S == "some name" &&
				*item["donor"].M["dob"].S == "1976-06-27" &&
				*item["donor"].M["postcode"].S == "B7A 8FJ"
		})).
		Return(nil)

	resp, err := l.HandleEvent(generateProxyRequest(Request{
		Type:   "personal-welfare",
		Source: "PHONE",
		Donor: Donor{
			Name:        "some name",
			DateOfBirth: "1976-06-27",
			Postcode:    "B7A 8FJ",
		},
	}))

	assert.Equal(t, 201, resp.StatusCode)
	assert.Nil(t, err)

	var response Response
	_ = json.Unmarshal([]byte(resp.Body), &response)

	assert.Regexp(t, `^M(-[346789QWERTYUPADFGHJKLXCVBNM]{4}){3}$`, response.Uid)
}

func TestHandleEventSaveError(t *testing.T) {
	err := errors.New(("an error"))

	mDdb := new(mockDynamoDB)

	logger := &mockLogger{}
	logger.On("Print", mock.Anything)

	l := Lambda{
		ddb:       mDdb,
		tableName: "my-table",
		logger:    logger,
	}

	mDdb.On("GetItem", "my-table", mock.Anything).Return(&dynamodb.GetItemOutput{}, nil)

	mDdb.On("PutItem", "my-table", mock.Anything).Return(err)

	resp, err := l.HandleEvent(generateProxyRequest(Request{
		Type:   "personal-welfare",
		Source: "PHONE",
		Donor: Donor{
			Name:        "some name",
			DateOfBirth: "1976-06-27",
			Postcode:    "B7A 8FJ",
		},
	}))

	assert.Equal(t, 500, resp.StatusCode)
	assert.Nil(t, err)

	var problem Problem
	_ = json.Unmarshal([]byte(resp.Body), &problem)

	assert.Equal(t, "INTERNAL_SERVER_ERROR", problem.Code)
	assert.Equal(t, "Internal server error", problem.Detail)
}

func TestHandleUIDRegeneratedIfNotUnique(t *testing.T) {
	mDdb := new(mockDynamoDB)
	l := Lambda{
		ddb:       mDdb,
		tableName: "my-table",
	}

	var reUid = regexp.MustCompile(`^M-[346789QWERTYUPADFGHJKLXCVBNM]{12}$`)

	mDdb.
		On("GetItem", "my-table", mock.MatchedBy(func(key map[string]*dynamodb.AttributeValue) bool {
			return reUid.MatchString(*key["uid"].S)
		})).
		Return(&dynamodb.GetItemOutput{
			Item: map[string]*dynamodb.AttributeValue{
				"uid": {S: aws.String("M-7PL7MA8DF8LD")},
			},
		}, nil).Twice()

	mDdb.
		On("GetItem", "my-table", mock.MatchedBy(func(key map[string]*dynamodb.AttributeValue) bool {
			return reUid.MatchString(*key["uid"].S)
		})).
		Return(&dynamodb.GetItemOutput{}, nil).Once()

	mDdb.
		On("PutItem", "my-table", mock.MatchedBy(func(item map[string]*dynamodb.AttributeValue) bool {
			return reUid.MatchString(*item["uid"].S) &&
				validateChecksum((*item["uid"].S)[2:]) &&
				*item["source"].S == "PHONE" &&
				*item["type"].S == "personal-welfare" &&
				*item["donor"].M["name"].S == "some name" &&
				*item["donor"].M["dob"].S == "1976-06-27" &&
				*item["donor"].M["postcode"].S == "B7A 8FJ"
		})).
		Return(nil)

	resp, err := l.HandleEvent(generateProxyRequest(Request{
		Type:   "personal-welfare",
		Source: "PHONE",
		Donor: Donor{
			Name:        "some name",
			DateOfBirth: "1976-06-27",
			Postcode:    "B7A 8FJ",
		},
	}))

	mDdb.AssertNumberOfCalls(t, "GetItem", 3)

	assert.Equal(t, 201, resp.StatusCode)
	assert.Nil(t, err)

	var response Response
	_ = json.Unmarshal([]byte(resp.Body), &response)

	assert.Regexp(t, `^M(-[346789QWERTYUPADFGHJKLXCVBNM]{4}){3}$`, response.Uid)
	mock.AssertExpectationsForObjects(t, mDdb)
}

func TestHypenateUID(t *testing.T) {
	assert.Equal(t, "M-FH4D-E694-A8LC", hyphenateUID("M-FH4DE694A8LC"))
}
