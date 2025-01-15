FROM golang:1.23.2 AS build-stage
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -C . -o /app/dp-test

# Deploy the application binary into a lean image
FROM alpine:3.20.3 AS release-stage
WORKDIR /
COPY --from=build-stage /app/dp-test /dp-test
# create non-root user
RUN set -ex; \
addgroup --gid 1000 -S nonroot; \
adduser --uid 1000 -D -S -h / -s /sbin/nologin -G nonroot nonroot; \
mkdir "/etc/dp-golang"; \
chown -R nonroot:nonroot "/etc/dp-golang";
USER nonroot:nonroot
ENTRYPOINT ["/dp-test"]
