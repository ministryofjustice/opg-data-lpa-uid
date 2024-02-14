package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"flag"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	v4 "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
	"github.com/aws/aws-sdk-go-v2/config"
)

const apiGatewayPath = "/cases"

type RequestSigner struct {
	v4Signer    *v4.Signer
	credentials aws.Credentials
	awsRegion   string
}

func main() {
	baseUrl := flag.String("baseUrl", "https://development.lpa-uid.api.opg.service.justice.gov.uk", "Base URL of UID service (defaults to 'https://development.lpa-uid.api.opg.service.justice.gov.uk'")
	requestBody := flag.String("body", `{"type":"property-and-affairs","source":"APPLICANT","donor":{"name":"Jamie Smith","dob":"2000-01-02","postcode":"B14 7ED"}}`, "Body POSTed to the service (defaults to a valid body)")

	flag.Parse()

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	httpClient := &http.Client{Timeout: 10 * time.Second}

	credentials, err := cfg.Credentials.Retrieve(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	req := buildRequest(*baseUrl, *requestBody)

	signer := RequestSigner{v4Signer: v4.NewSigner(), credentials: credentials, awsRegion: cfg.Region}
	err = signer.Sign(context.TODO(), req)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Request headers:\n")

	for name, values := range req.Header {
		for _, value := range values {
			log.Println(name, value+"\n")
		}
	}

	log.Println("Request body: " + *requestBody + "\n")
	log.Println("POSTing to: " + req.URL.String())

	resp, err := httpClient.Do(req)
	if err != nil {
		log.Fatal(err)
	}

	defer resp.Body.Close()
	responseBody, _ := io.ReadAll(resp.Body)

	if resp.StatusCode > http.StatusCreated {
		log.Println("Response headers:\n")

		for name, values := range resp.Header {
			for _, value := range values {
				log.Println(name, value+"\n")
			}
		}

		log.Fatalf("error POSTing to UID service: (%d) %s", resp.StatusCode, string(responseBody))
	}

	log.Printf("Success (%d). Response body: %s", resp.StatusCode, responseBody)
}

func buildRequest(baseUrl, body string) *http.Request {
	r, err := http.NewRequest(http.MethodPost, baseUrl+apiGatewayPath, bytes.NewReader([]byte(body)))
	if err != nil {
		log.Fatal(err)
	}

	r.Header.Add("Content-Type", "application/json")
	return r
}

func (rs *RequestSigner) Sign(ctx context.Context, req *http.Request) error {
	reqBody := []byte("")

	if req.Body != nil {
		body, err := io.ReadAll(req.Body)
		if err != nil {
			return err
		}

		reqBody = body
	}

	hash := sha256.New()
	hash.Write(reqBody)
	encodedBody := hex.EncodeToString(hash.Sum(nil))

	req.Body = io.NopCloser(bytes.NewBuffer(reqBody))

	err := rs.v4Signer.SignHTTP(ctx, rs.credentials, req, encodedBody, "execute-api", rs.awsRegion, time.Now())
	if err != nil {
		return err
	}

	return nil
}
