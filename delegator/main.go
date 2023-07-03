package main

import (
	"encoding/json"
	"fmt"
	"html"
	"io"
	"log"
	"net/http"
	"regexp"
)

var rPath = regexp.MustCompile("/2015-03-31/functions/lpa-uid-([a-z-]+)-local-eu-west-([1|2]{1})/invocations")

func delegateHandler(w http.ResponseWriter, r *http.Request) {
	if rPath.MatchString(r.URL.Path) {
		switch r.Method {
		case http.MethodPost:
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

			body, _ := io.ReadAll(resp.Body)

			w.WriteHeader(http.StatusOK)
			w.Write(body)
		case http.MethodGet:
			w.WriteHeader(http.StatusOK)
			w.Header().Set("Content-Type", "application/json")

			resp := make(map[string]string)
			resp["status"] = "OK"
			jsonResp, _ := json.Marshal(resp)

			w.Write(jsonResp)
		default:
			http.Error(w, fmt.Sprintf("couldn't match URL: %s", html.EscapeString(r.URL.Path)), http.StatusInternalServerError)
		}

	}
}

func main() {
	http.HandleFunc("/2015-03-31/functions/", delegateHandler)

	fmt.Printf("Starting server at port 8080\n")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
