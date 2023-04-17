package main

import (
	"encoding/json"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
)

type Error struct {
	Source string `json:"source"`
	Detail string `json:"detail"`
}

type Problem struct {
	StatusCode int     `json:"-"`
	Code       string  `json:"code"`
	Detail     string  `json:"detail"`
	Errors     []Error `json:"errors,omitempty"`
}

type LogEvent struct {
	ServiceName string    `json:"service_name"`
	Timestamp   time.Time `json:"timestamp"`
	Status      int       `json:"status"`
	Problem     Problem   `json:"problem"`
}

var ProblemInternalServerError Problem = Problem{
	StatusCode: 500,
	Code:       "INTERNAL_SERVER_ERROR",
	Detail:     "Internal server error",
}

var ProblemInvalidRequest Problem = Problem{
	StatusCode: 400,
	Code:       "INVALID_REQUEST",
	Detail:     "Invalid request",
}

func (problem Problem) Respond() (events.APIGatewayProxyResponse, error) {
	err := json.NewEncoder(os.Stdout).Encode(LogEvent{
		ServiceName: "opg-data-lpa-uid",
		Timestamp:   time.Now(),
		Status:      problem.StatusCode,
		Problem:     problem,
	})

	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: 500,
			Body:       "{\"code\":\"INTERNAL_SERVER_ERROR\",\"detail\":\"Internal server error\"}",
		}, nil
	}

	code := problem.StatusCode
	body, err := json.Marshal(problem)

	if err != nil {
		code = 500
		body = []byte("{\"code\":\"INTERNAL_SERVER_ERROR\",\"detail\":\"Internal server error\"}")
	}

	return events.APIGatewayProxyResponse{
		StatusCode: code,
		Body:       string(body),
	}, nil
}
