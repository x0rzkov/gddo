FROM golang:1.13-alpine AS builder

ARG TWINT_GENERATOR_VERSION

RUN apk add --no-cache make

COPY .  /go/src/github.com/golang/gddo
WORKDIR /go/src/github.com/golang/gddo

RUN cd /go/src/github.com/golang/gddo \
    && cd gddo-admin \
    && go build -v \
    && cd ../gddo-server \
    && go build -v

FROM alpine:3.10 AS runtime

# Build argument
ARG VERSION
ARG BUILD
ARG NOW

# Install runtime dependencies & create runtime user
RUN apk --no-cache --no-progress add ca-certificates \
 && mkdir -p /opt \
 && adduser -D golang -h /opt/gddo -s /bin/sh \
 && su golang -c 'cd /opt/gddo; mkdir -p bin config data'

# Switch to user context
USER golang
WORKDIR /opt/gddo/data

# Copy gddo binary to /opt/gddo/bin
COPY --from=builder /go/src/github.com/golang/gddo/gddo-server/gddo-server /opt/gddo/bin/gddo-server
COPY --from=builder /go/src/github.com/golang/gddo/gddo-server/assets /opt/gddo/data/assets
COPY --from=builder /go/src/github.com/golang/gddo/gddo-admin/gddo-admin /opt/gddo/bin/gddo-admin

ENV PATH $PATH:/opt/gddo/bin

# Container metadata
LABEL name="gddo" \
      version="$VERSION" \
      build="$BUILD" \
      architecture="x86_64" \
      build_date="$NOW" \
      vendor="golang" \
      maintainer="x0rzkov <x0rzkov@protonmail.com>" \
      url="https://github.com/golang/gddo" \
      summary="Dockerized gddo project" \
      description="Dockerized gddo project" \
      vcs-type="git" \
      vcs-url="https://github.com/golang/gddo" \
      vcs-ref="$VERSION" \
      distribution-scope="public"

# Container configuration
VOLUME ["/opt/gddo/data"]
CMD ["gddo-server"]




