package main

import (
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type MyResponse struct {
	Message string `json:"message"`
}

type Lambda struct{}

func (l *Lambda) HandleEvent(event events.APIGatewayProxyRequest) (MyResponse, error) {
	return MyResponse{Message: fmt.Sprintf("you sent body: %s", event.Body)}, nil
}

func main() {
	l := &Lambda{}

	lambda.Start(l.HandleEvent)
}
