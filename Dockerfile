FROM golang:1.19 AS dev
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go install github.com/cespare/reflex@latest
EXPOSE 5000
CMD reflex -r '\.go$' -s -- sh -c "go run cmd/server/main.go"

# ---------- Build stage ----------
FROM golang:1.19 AS build
ENV GOOS=linux
ENV CGO_ENABLED=0
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
# download mdbook to compile docs
RUN wget https://github.com/rust-lang/mdBook/releases/download/v0.4.25/mdbook-v0.4.25-x86_64-unknown-linux-gnu.tar.gz
RUN tar -xzf mdbook-v0.4.25-x86_64-unknown-linux-gnu.tar.gz
COPY . .
RUN go build -o server cmd/server/main.go
RUN ./mdbook build

# ---------- Production stage ----------
FROM alpine:latest AS prod
RUN apk add --no-cache ca-certificates
WORKDIR /root/
COPY --from=build /app/server .
EXPOSE 5000
CMD ["./server"]
