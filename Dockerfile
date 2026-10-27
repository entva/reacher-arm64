FROM rust:1.99.1-alpine3.24 AS build
RUN apk add --no-cache musl-dev perl make gcc linux-headers
WORKDIR /src
COPY . .
ENV SQLX_OFFLINE=true
RUN cargo build --release --bin reacher_backend

FROM alpine:3.24.3
RUN apk add --no-cache chromium chromium-chromedriver ca-certificates \
 && adduser -D -h /home/reacher reacher
WORKDIR /home/reacher
COPY --from=build /src/target/release/reacher_backend .
COPY --from=build /src/backend/backend_config.toml .
USER reacher
ENV RCH__HTTP_HOST=0.0.0.0 RCH__WORKER__ENABLE=false RUST_LOG=reacher=info
EXPOSE 8080
CMD ["/bin/sh", "-c", "chromedriver --port=9515 & exec ./reacher_backend"]
