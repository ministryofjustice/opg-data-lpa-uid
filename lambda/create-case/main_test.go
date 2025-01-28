package main

import (
	"net/http"
	"testing"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

var (
	testNow   = time.Now()
	testNowFn = func() time.Time { return testNow }
)

func TestHandleEvent(t *testing.T) {
	dynamo := newMockDynamo(t)
	dynamo.EXPECT().
		GetItem(mock.Anything, mock.Anything).
		Return(&dynamodb.GetItemOutput{Item: map[string]types.AttributeValue{
			"Maximum": &types.AttributeValueMemberN{Value: "6"},
		}}, nil)
	dynamo.EXPECT().
		TransactWriteItems(mock.Anything, &dynamodb.TransactWriteItemsInput{
			TransactItems: []types.TransactWriteItem{
				{
					Update: &types.Update{
						TableName: aws.String("T"),
						Key: map[string]types.AttributeValue{
							"uid": &types.AttributeValueMemberS{Value: "#METADATA"},
						},
						ConditionExpression: aws.String("Maximum = :currentMaximum"),
						UpdateExpression:    aws.String("SET Maximum = :nextMaximum"),
						ExpressionAttributeValues: map[string]types.AttributeValue{
							":currentMaximum": &types.AttributeValueMemberN{Value: "6"},
							":nextMaximum":    &types.AttributeValueMemberN{Value: "7"},
						},
					},
				},
				{
					Put: &types.Put{
						TableName: aws.String("T"),
						Item: map[string]types.AttributeValue{
							"uid":        &types.AttributeValueMemberS{Value: "M-5002-8368-4109"},
							"created_at": &types.AttributeValueMemberS{Value: testNow.Format(time.RFC3339Nano)},
							"type":       &types.AttributeValueMemberS{Value: "personal-welfare"},
							"source":     &types.AttributeValueMemberS{Value: "PHONE"},
							"donor": &types.AttributeValueMemberM{Value: map[string]types.AttributeValue{
								"name":     &types.AttributeValueMemberS{Value: "some name"},
								"dob":      &types.AttributeValueMemberS{Value: "1976-06-27"},
								"postcode": &types.AttributeValueMemberS{Value: "B7A 8FJ"},
							}},
						},
						ConditionExpression: aws.String("attribute_not_exists(uid)"),
					},
				},
			},
		}).
		Return(nil, nil)

	logger := newMockLogger(t)
	logger.EXPECT().
		DebugContext(mock.Anything, mock.Anything, mock.Anything)

	l := &Lambda{dynamo: dynamo, logger: logger, tableName: "T", now: testNowFn}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: `{
			"type": "personal-welfare",
			"source": "PHONE",
			"donor": {
				"name": "some name",
				"dob": "1976-06-27",
				"postcode": "B7A 8FJ"
			}
		}`,
	})

	assert.Nil(t, err)
	assert.Equal(t, http.StatusCreated, resp.StatusCode)
	assert.JSONEq(t, `{"uid": "M-5002-8368-4109"}`, resp.Body)
}

func TestHandleEventWhenInitialUID(t *testing.T) {
	dynamo := newMockDynamo(t)
	dynamo.EXPECT().
		GetItem(mock.Anything, mock.Anything).
		Return(&dynamodb.GetItemOutput{}, nil)
	dynamo.EXPECT().
		TransactWriteItems(mock.Anything, &dynamodb.TransactWriteItemsInput{
			TransactItems: []types.TransactWriteItem{
				{
					Put: &types.Put{
						TableName: aws.String("T"),
						Item: map[string]types.AttributeValue{
							"uid":     &types.AttributeValueMemberS{Value: "#METADATA"},
							"Maximum": &types.AttributeValueMemberN{Value: "1"},
						},
						ConditionExpression: aws.String("attribute_not_exists(uid)"),
					},
				},
				{
					Put: &types.Put{
						TableName: aws.String("T"),
						Item: map[string]types.AttributeValue{
							"uid":        &types.AttributeValueMemberS{Value: "M-3779-9919-9529"},
							"created_at": &types.AttributeValueMemberS{Value: testNow.Format(time.RFC3339Nano)},
							"type":       &types.AttributeValueMemberS{Value: "personal-welfare"},
							"source":     &types.AttributeValueMemberS{Value: "PHONE"},
							"donor": &types.AttributeValueMemberM{Value: map[string]types.AttributeValue{
								"name":     &types.AttributeValueMemberS{Value: "some name"},
								"dob":      &types.AttributeValueMemberS{Value: "1976-06-27"},
								"postcode": &types.AttributeValueMemberS{Value: "B7A 8FJ"},
							}},
						},
						ConditionExpression: aws.String("attribute_not_exists(uid)"),
					},
				},
			},
		}).
		Return(nil, nil)

	logger := newMockLogger(t)
	logger.EXPECT().
		DebugContext(mock.Anything, mock.Anything, mock.Anything)

	l := &Lambda{dynamo: dynamo, logger: logger, tableName: "T", now: testNowFn}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: `{
			"type": "personal-welfare",
			"source": "PHONE",
			"donor": {
				"name": "some name",
				"dob": "1976-06-27",
				"postcode": "B7A 8FJ"
			}
		}`,
	})

	assert.Nil(t, err)
	assert.Equal(t, http.StatusCreated, resp.StatusCode)
	assert.JSONEq(t, `{"uid": "M-3779-9919-9529"}`, resp.Body)
}

func TestHandleEventWhenMetadataConflict(t *testing.T) {
	dynamo := newMockDynamo(t)
	dynamo.EXPECT().
		GetItem(mock.Anything, mock.Anything).
		Return(&dynamodb.GetItemOutput{Item: map[string]types.AttributeValue{
			"Maximum": &types.AttributeValueMemberN{Value: "6"},
		}}, nil).
		Once()
	dynamo.EXPECT().
		TransactWriteItems(mock.Anything, mock.MatchedBy(func(input *dynamodb.TransactWriteItemsInput) bool {
			var currentMaximum int
			attributevalue.Unmarshal(input.TransactItems[0].Update.ExpressionAttributeValues[":currentMaximum"], &currentMaximum)
			return currentMaximum == 6
		})).
		Return(nil, &types.TransactionCanceledException{
			CancellationReasons: []types.CancellationReason{
				{Code: aws.String("ConditionalCheckFailed")},
				{Code: aws.String("ConditionalCheckFailed")},
			},
		}).
		Once()
	dynamo.EXPECT().
		GetItem(mock.Anything, mock.Anything).
		Return(&dynamodb.GetItemOutput{Item: map[string]types.AttributeValue{
			"Maximum": &types.AttributeValueMemberN{Value: "7"},
		}}, nil).
		Once()
	dynamo.EXPECT().
		TransactWriteItems(mock.Anything, mock.MatchedBy(func(input *dynamodb.TransactWriteItemsInput) bool {
			var currentMaximum int
			attributevalue.Unmarshal(input.TransactItems[0].Update.ExpressionAttributeValues[":currentMaximum"], &currentMaximum)
			return currentMaximum == 7
		})).
		Return(nil, nil).
		Once()

	logger := newMockLogger(t)
	logger.EXPECT().
		DebugContext(mock.Anything, mock.Anything, mock.Anything)

	l := &Lambda{dynamo: dynamo, logger: logger, tableName: "T", now: testNowFn}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: `{
			"type": "personal-welfare",
			"source": "PHONE",
			"donor": {
				"name": "some name",
				"dob": "1976-06-27",
				"postcode": "B7A 8FJ"
			}
		}`,
	})

	assert.Nil(t, err)
	assert.Equal(t, http.StatusCreated, resp.StatusCode)
	assert.JSONEq(t, `{"uid": "M-5206-6443-1532"}`, resp.Body)
}

func TestHandleEventWhenEmptyBody(t *testing.T) {
	logger := newMockLogger(t)
	logger.EXPECT().
		DebugContext(mock.Anything, mock.Anything, mock.Anything)
	logger.EXPECT().
		ErrorContext(mock.Anything, mock.Anything, mock.Anything)

	l := &Lambda{logger: logger}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: "",
	})

	assert.Nil(t, err)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	assert.JSONEq(t, `{"code":"INVALID_REQUEST","detail":"Invalid request"}`, resp.Body)
}

func TestHandleEventWhenInvalidBodyMissingRequiredFields(t *testing.T) {
	logger := newMockLogger(t)
	logger.EXPECT().
		DebugContext(mock.Anything, mock.Anything, mock.Anything)

	l := &Lambda{logger: logger}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: "{}",
	})

	assert.Nil(t, err)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	assert.JSONEq(t, `{
		"code":"INVALID_REQUEST",
		"detail":"Invalid request",
		"errors": [
			{"source":"/source","detail":"required"},
			{"source":"/type","detail":"required"},
			{"source":"/donor/name","detail":"required"},
			{"source":"/donor/dob","detail":"required"},
			{"source":"/donor/postcode","detail":"required"}
		]
	}`, resp.Body)
}

func TestHandleEventWhenInvalidBodyHasInvalidFields(t *testing.T) {
	logger := newMockLogger(t)
	logger.EXPECT().
		DebugContext(mock.Anything, mock.Anything, mock.Anything)

	l := &Lambda{logger: logger}

	resp, err := l.HandleEvent(events.APIGatewayProxyRequest{
		Body: `{
			"type": "bad",
			"source": "bad",
			"donor": {
				"name": "some name",
				"dob": "27/06/1976",
				"postcode": "bad"
			}
		}`,
	})

	assert.Nil(t, err)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	assert.JSONEq(t, `{
		"code":"INVALID_REQUEST",
		"detail":"Invalid request",
		"errors": [
			{"source":"/source","detail":"must be APPLICANT or PHONE"},
			{"source":"/type","detail":"must be personal-welfare or property-and-affairs"},
			{"source":"/donor/dob","detail":"must match format YYYY-MM-DD"},
			{"source":"/donor/postcode","detail":"must be a valid postcode"}
		]
	}`, resp.Body)
}
