#!/bin/bash

GOOS=linux GOARCH=amd64 go build -o sni-listener-linux-amd64 sni-listener.go
