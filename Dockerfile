# ---------- Build stage ----------
    FROM golang:1.19 AS build
    WORKDIR /app
    
    # Install dependencies
    COPY go.mod go.sum ./
    RUN go mod download
    
    # Copy the project
    COPY . .
    
    # Build the Go server
    RUN go build -o server cmd/server/main.go
    
    # ---------- Production stage ----------
    FROM golang:1.19 AS prod
    WORKDIR /root/
    
    # Copy server binary and static files
    COPY --from=build /app/server .
    COPY --from=build /app/book ./book
    
    # Expose port (Railway will use $PORT automatically)
    EXPOSE 5000
    
    # Start the server
    CMD ["./server"]
    