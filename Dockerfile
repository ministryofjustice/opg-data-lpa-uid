FROM golang:1.24.4 AS build-env

WORKDIR /app

COPY go.mod go.sum ./
COPY lambda ./lambda
COPY internal ./internal

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o /go/bin/main ./lambda/create-case

FROM alpine:3

COPY --from=build-env /go/bin/main /var/task/main

ENTRYPOINT [ "/var/task/main" ]
