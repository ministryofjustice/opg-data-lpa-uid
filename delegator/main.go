package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strings"

	"github.com/aws/aws-lambda-go/events"
)

var rPath = regexp.MustCompile("/2015-03-31/functions/lpa-uid-([a-z-]+)-local-eu-west-1/invocations")

type ApiGatewayResponse struct {
	IsBase64Encoded bool        `json:"isBase64Encoded"`
	StatusCode      int         `json:"statusCode"`
	Headers         http.Header `json:"headers"`
	Body            string      `json:"body"`
}

func delegateHandler(w http.ResponseWriter, r *http.Request) {
	if rPath.MatchString(r.URL.Path) && r.Method == "POST" {

		matches := rPath.FindStringSubmatch(r.URL.Path)
		lambdaName := matches[1]

		log.Printf("function name: %s", lambdaName)

		// aws-lambda-rie requires the function to be called "function"
		url := fmt.Sprintf("http://lambda-%s:8080/2015-03-31/functions/function/invocations", lambdaName)
		proxyReq, err := http.NewRequest(r.Method, url, r.Body)
		if err != nil {
			log.Printf("error: couldn't create proxy request")
		}

		for header, values := range r.Header {
			for _, value := range values {
				proxyReq.Header.Add(header, value)
			}
		}

		client := &http.Client{}
		resp, err := client.Do(proxyReq)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		body := new(strings.Builder)
		_, _ = io.Copy(body, resp.Body)

		out := events.APIGatewayProxyResponse{
			IsBase64Encoded:   false,
			StatusCode:        resp.StatusCode,
			MultiValueHeaders: resp.Header,
			Body:              body.String(),
		}

		jsonOut, _ := json.Marshal(out)
		w.WriteHeader(http.StatusOK)
		w.Write(jsonOut)
	} else {
		http.Error(w, fmt.Sprintf("couldn't match URL: %s", r.URL.Path), http.StatusInternalServerError)
	}
}

func main() {
	http.HandleFunc("/2015-03-31/functions/", delegateHandler)

	fmt.Printf("Starting server at port 8080\n")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
