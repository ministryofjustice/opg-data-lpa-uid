package event

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

var (
	expectedError = errors.New("err")
	testNow       = time.Date(2023, time.April, 2, 3, 4, 5, 6, time.UTC)
	testNowFn     = func() time.Time { return testNow }
)

func TestClientSendMetric(t *testing.T) {
	ctx := context.Background()
	data, _ := json.Marshal(Metrics{
		Metrics: []MetricWrapper{{
			Metric: Metric{
				Project:          "LPAUID",
				Category:         "metric",
				Subcategory:      "CAT",
				Environment:      "ENV",
				MeasureName:      "ME",
				MeasureValue:     "1",
				MeasureValueType: "BIGINT",
				Time:             strconv.FormatInt(testNow.UnixMilli(), 10),
			},
		}},
	})

	svc := newMockEventbridgeClient(t)
	svc.EXPECT().
		PutEvents(mock.Anything, &eventbridge.PutEventsInput{
			Entries: []types.PutEventsRequestEntry{{
				EventBusName: aws.String("my-bus"),
				Source:       aws.String("opg.poas.lpauid"),
				DetailType:   aws.String("metric"),
				Detail:       aws.String(string(data)),
			}},
		}).
		Return(nil, nil)

	client := &Client{svc: svc, eventBusName: "my-bus", environment: "ENV", now: testNowFn}
	err := client.SendMetric(ctx, "CAT", "ME")

	assert.Nil(t, err)
}

func TestClientSendMetricWhenPutEventsError(t *testing.T) {
	ctx := context.Background()

	svc := newMockEventbridgeClient(t)
	svc.EXPECT().
		PutEvents(mock.Anything, mock.Anything).
		Return(nil, expectedError)

	client := &Client{svc: svc, eventBusName: "my-bus", environment: "ENV", now: testNowFn}
	err := client.SendMetric(ctx, "CAT", "ME")

	assert.Equal(t, expectedError, err)
}
