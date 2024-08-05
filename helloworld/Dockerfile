FROM golang:1.22-alpine AS builder

COPY . .
RUN go build -o server main.go

FROM scratch
COPY --from=builder /go/server /
EXPOSE 8080/tcp
EXPOSE 8081/tcp
ENTRYPOINT ["/server"]
