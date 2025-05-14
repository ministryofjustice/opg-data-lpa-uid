package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge"
	"github.com/aws/aws-sdk-go-v2/service/eventbridge/types"
)

// Timeout is how long a request can be fulfilled for, before being terminated
// and returning a 408 Request Timeout response.
const Timeout = 3 * time.Second

type Request struct {
	Type   LpaType   `json:"type"`
	Source LpaSource `json:"source"`
	Donor  Donor     `json:"donor"`
}

type Response struct {
	Uid string `json:"uid"`
}

type Dynamo interface {
	GetItem(ctx context.Context, params *dynamodb.GetItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.GetItemOutput, error)
	TransactWriteItems(ctx context.Context, params *dynamodb.TransactWriteItemsInput, optFns ...func(*dynamodb.Options)) (*dynamodb.TransactWriteItemsOutput, error)
}

type Eventbridge interface {
	PutEvents(ctx context.Context, params *eventbridge.PutEventsInput, optFns ...func(*eventbridge.Options)) (*eventbridge.PutEventsOutput, error)
}

type Logger interface {
	DebugContext(ctx context.Context, msg string, args ...any)
	WarnContext(ctx context.Context, msg string, args ...any)
	ErrorContext(ctx context.Context, msg string, args ...any)
}

type Metrics struct {
	Metrics []Metric `json:"metrics"`
}

type Metric struct {
	Project          string
	Category         string
	Subcategory      string
	Environment      string
	MeasureName      string
	MeasureValue     string
	MeasureValueType string
	Time             string
}

type Lambda struct {
	dynamo       Dynamo
	tableName    string
	eventbridge  Eventbridge
	eventBusName string
	logger       Logger
	environment  string
	now          func() time.Time
}

func (l *Lambda) HandleEvent(event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	ctx, cancel := context.WithTimeout(context.Background(), Timeout)
	defer cancel()

	l.logger.DebugContext(ctx, "event", slog.String("body", event.Body))

	var data Request
	if err := json.Unmarshal([]byte(event.Body), &data); err != nil {
		l.logger.ErrorContext(ctx, "error unmarshalling request", slog.Any("err", err))
		return ProblemInvalidRequest.Respond()
	}

	if validationErrors := validate(data); len(validationErrors) > 0 {
		problem := ProblemInvalidRequest
		problem.Errors = validationErrors
		return problem.Respond()
	}

	l.logger.DebugContext(ctx, "request validated")

	for {
		select {
		case <-ctx.Done():
			l.logger.ErrorContext(ctx, "timed out")
			return ProblemRequestTimeout.Respond()

		default:
			max, err := l.getMaximum(ctx)
			if err != nil {
				l.logger.ErrorContext(ctx, "error getting maximum", slog.Any("err", err))
				return ProblemInternalServerError.Respond()
			}

			if err := l.insertLpa(ctx, max, data); err != nil {
				if errors.Is(err, ErrMetadataChanged) {
					continue
				}

				l.logger.ErrorContext(ctx, "error inserting lpa", slog.Any("err", err))
				return ProblemInternalServerError.Respond()
			}

			if metricEvent, err := json.Marshal(Metrics{
				Metrics: []Metric{{
					Project:          "MRLPA",
					Category:         "metric",
					Subcategory:      "DonorStubs",
					Environment:      l.environment,
					MeasureName:      "CREATED",
					MeasureValue:     "1",
					MeasureValueType: "BIGINT",
					Time:             strconv.FormatInt(l.now().UnixMilli(), 10),
				}},
			}); err != nil {
				l.logger.WarnContext(ctx, "problem marshalling metric", slog.Any("err", err))
			} else {
				if _, err := l.eventbridge.PutEvents(ctx, &eventbridge.PutEventsInput{
					Entries: []types.PutEventsRequestEntry{{
						EventBusName: aws.String(l.eventBusName),
						Source:       aws.String("opg.poas.uid"),
						DetailType:   aws.String("metric"),
						Detail:       aws.String(string(metricEvent)),
					}},
				}); err != nil {
					l.logger.WarnContext(ctx, "problem sending metric", slog.Any("err", err))
				}
			}

			response := Response{Uid: formatUID(max + 1)}

			body, err := json.Marshal(response)
			if err != nil {
				l.logger.ErrorContext(ctx, "error marshalling response", slog.Any("err", err))
				return ProblemInternalServerError.Respond()
			}

			l.logger.DebugContext(ctx, "response", slog.String("body", string(body)))

			return events.APIGatewayProxyResponse{
				StatusCode: 201,
				Body:       string(body),
			}, nil
		}
	}
}

func main() {
	var (
		ctx          = context.Background()
		awsBaseURL   = os.Getenv("AWS_BASE_URL")
		tableName    = os.Getenv("AWS_DYNAMODB_TABLE_NAME")
		eventBusName = os.Getenv("EVENT_BUS_NAME")
		debug        = os.Getenv("DEBUG") == "1"
		environment  = os.Getenv("ENV")
	)

	level := slog.LevelInfo
	if debug {
		level = slog.LevelDebug
	}

	logger := slog.New(
		slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level}).
			WithAttrs([]slog.Attr{
				slog.String("service_name", "opg-data-lpa-uid"),
			}))

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		logger.ErrorContext(ctx, "failed to load default config", slog.Any("err", err))
		return
	}

	if len(awsBaseURL) > 0 {
		cfg.BaseEndpoint = aws.String(awsBaseURL)
	}

	l := &Lambda{
		logger:       logger,
		dynamo:       dynamodb.NewFromConfig(cfg),
		tableName:    tableName,
		eventbridge:  eventbridge.NewFromConfig(cfg),
		eventBusName: eventBusName,
		environment:  environment,
		now:          time.Now,
	}

	lambda.Start(l.HandleEvent)
}
