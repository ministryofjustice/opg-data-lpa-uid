package main

import (
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

type TestEvent struct {
	Message string `json:"message"`
}

type MyResponse struct {
	Message string `json:"message"`
}

type Lambda struct{}

// func (l *Lambda) HandleEvent(event events.APIGatewayProxyRequest) (MyResponse, error) {
func (l *Lambda) HandleEvent(event TestEvent) (MyResponse, error) {
	return MyResponse{Message: fmt.Sprintf("you sent body: %s", event.Message)}, nil
}

func main() {
	l := &Lambda{}

	lambda.Start(l.HandleEvent)
}
