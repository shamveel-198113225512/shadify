# ---------- Build stage ----------
    FROM golang:1.19 AS build
    WORKDIR /app
    
    # Copy go modules first for caching
    COPY go.mod go.sum ./
    RUN go mod download
    
    # Download mdBook to build docs
    RUN wget https://github.com/rust-lang/mdBook/releases/download/v0.4.25/mdbook-v0.4.25-x86_64-unknown-linux-gnu.tar.gz
    RUN tar -xzf mdbook-v0.4.25-x86_64-unknown-linux-gnu.tar.gz
    
    # Copy the rest of the project
    COPY . .
    
    # Build a fully static Go binary for Alpine
    RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server cmd/server/main.go
    
    # Build static docs
    RUN ./mdbook build
    
    # ---------- Production stage ----------
    FROM alpine:latest AS prod
    RUN apk add --no-cache ca-certificates
    
    WORKDIR /root/
    
    # Copy the statically built server binary and the book folder
    COPY --from=build /app/server .
    COPY --from=build /app/book ./book
    
    # Make sure binary is executable
    RUN chmod +x server
    
    # Expose port (Railway will override with $PORT)
    EXPOSE 5000
    
    # Start the server
    CMD ["./server"]
    