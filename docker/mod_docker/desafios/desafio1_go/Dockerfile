FROM golang:1.14-alpine as builder

WORKDIR /go/src

ADD . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-w -extldflags "-static"' -o main

FROM scratch
COPY --from=builder /go/src .
   
CMD ["./main"]