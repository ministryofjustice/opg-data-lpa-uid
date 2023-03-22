package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
)

var rPath = regexp.MustCompile("/2015-03-31/functions/([a-z-]+)/invocations")

var lambdaMap = map[string]string{
	"lpa-uid-default": "lambda-create-case",
}

func delegateHandler(w http.ResponseWriter, r *http.Request) {
	if rPath.MatchString(r.URL.Path) && r.Method == "POST" {

		matches := rPath.FindStringSubmatch(r.URL.Path)
		lambdaName := matches[1]

		log.Printf("function name: %s", lambdaName)

		container := lambdaMap[lambdaName]
		if container == "" {
			http.Error(w, fmt.Sprintf("could not find container for %s", lambdaName), http.StatusInternalServerError)
			return
		}

		log.Printf("forwarding to: %s", container)

		// aws-lambda-rie requires the function to be called "function"
		url := fmt.Sprintf("http://%s:8080/2015-03-31/functions/function/invocations", container)
		proxyReq, err := http.NewRequest(r.Method, url, r.Body)
		log.Print(proxyReq)
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

		for k, vv := range resp.Header {
			for _, v := range vv {
				w.Header().Add(k, v)
			}
		}

		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
		resp.Body.Close()
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
