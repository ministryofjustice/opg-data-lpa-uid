package event

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge/types"
)

const source = "opg.poas.lpauid"

var events = map[any]string{
	(*Metrics)(nil): "metric",
}

type eventbridgeClient interface {
	PutEvents(ctx context.Context, params *eventbridge.PutEventsInput, optFns ...func(*eventbridge.Options)) (*eventbridge.PutEventsOutput, error)
}

type Client struct {
	svc          eventbridgeClient
	eventBusName string
	environment  string
	now          func() time.Time
}

func NewClient(cfg aws.Config, now func() time.Time, eventBusName, environment string) *Client {
	return &Client{
		svc:          eventbridge.NewFromConfig(cfg),
		eventBusName: eventBusName,
		environment:  environment,
		now:          now,
	}
}

func (c *Client) SendMetric(ctx context.Context, category Category, measure Measure) error {
	return send[Metrics](ctx, c, Metrics{
		Metrics: []MetricWrapper{{
			Metric: Metric{
				Project:          "LPAUID",
				Category:         "metric",
				Subcategory:      category,
				Environment:      c.environment,
				MeasureName:      measure,
				MeasureValue:     "1",
				MeasureValueType: "BIGINT",
				Time:             strconv.FormatInt(c.now().UnixMilli(), 10),
			},
		}},
	})
}

func send[T any](ctx context.Context, c *Client, detail any) error {
	detailType, ok := events[(*T)(nil)]
	if !ok {
		return errors.New("event send of unknown type")
	}

	v, err := json.Marshal(detail)
	if err != nil {
		return err
	}

	_, err = c.svc.PutEvents(ctx, &eventbridge.PutEventsInput{
		Entries: []types.PutEventsRequestEntry{{
			EventBusName: aws.String(c.eventBusName),
			Source:       aws.String(source),
			DetailType:   aws.String(detailType),
			Detail:       aws.String(string(v)),
		}},
	})

	return err
}
