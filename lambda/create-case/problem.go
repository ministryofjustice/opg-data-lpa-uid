package main

import (
	"encoding/json"

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
