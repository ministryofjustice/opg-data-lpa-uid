package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"

	"github.com/ministryofjustice/opg-data-lpa-uid/internal/event"
)

// Timeout is how long a request can be fulfilled for, before being terminated
// and returning a 408 Request Timeout response.
const Timeout = 6 * time.Second

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

type Logger interface {
	DebugContext(ctx context.Context, msg string, args ...any)
	ErrorContext(ctx context.Context, msg string, args ...any)
}

type EventClient interface {
	SendMetric(ctx context.Context, category event.Category, measure event.Measure) error
}

type Lambda struct {
	dynamo      Dynamo
	tableName   string
	logger      Logger
	now         func() time.Time
	eventClient EventClient
}

func (l *Lambda) HandleEvent(e events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	ctx, cancel := context.WithTimeout(context.Background(), Timeout)
	defer cancel()

	l.logger.DebugContext(ctx, "event", slog.String("body", e.Body))

	var data Request
	if err := json.Unmarshal([]byte(e.Body), &data); err != nil {
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

			if err = l.eventClient.SendMetric(ctx, event.CategoryLPAStub, event.MeasureCreated); err != nil {
				l.logger.ErrorContext(ctx, "error sending metric", slog.Any("err", err))
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
		debug        = os.Getenv("DEBUG") == "1"
		eventBusName = os.Getenv("EVENT_BUS_NAME")
		environment  = os.Getenv("ENVIRONMENT")
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
		logger:      logger,
		dynamo:      dynamodb.NewFromConfig(cfg),
		tableName:   tableName,
		now:         time.Now,
		eventClient: event.NewClient(cfg, time.Now, eventBusName, environment),
	}

	lambda.Start(l.HandleEvent)
}
