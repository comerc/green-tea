FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache ca-certificates wget

# Download and install Go 1.25
RUN wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
  tar -C /usr/local -xzf /tmp/go.tar.gz && \
  rm /tmp/go.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV GOROOT=/usr/local/go

WORKDIR /app

COPY main.go .

# Build both versions
RUN go build -o benchmark_std main.go
RUN GOEXPERIMENT=greenteagc go build -o benchmark_greentea main.go

# Entry point
COPY run_internal.sh .
RUN chmod +x run_internal.sh

CMD ["./run_internal.sh"]