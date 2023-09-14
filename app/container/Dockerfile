FROM golang:1.21.0
WORKDIR /app
COPY src/* ./
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o dex

FROM scratch
COPY --from=0 /app/dex /bin/dex
EXPOSE 80
CMD ["/bin/dex"]
