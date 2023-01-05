FROM --platform=${BUILDPLATFORM} golang:1.19-alpine3.17 AS base
ENV CGO_ENABLED=0

WORKDIR /src

COPY go.* .
RUN go mod download
COPY ./ ./

FROM base AS build
ARG TARGETOS
ARG TARGETARCH
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /out/example .

FROM base AS unit-test
RUN mkdir /out && go test -v -coverprofile=/out/cover.out ./...

FROM golangci/golangci-lint:v1.43-alpine AS lint-base

FROM base AS lint
RUN golangci-lint run --timeout 10m0s ./...

FROM scratch AS unit-test-coverage
COPY --from=unit-test /out/cover.out /cover.out

FROM scratch AS bin-unix
COPY --from=build /out/example /

FROM bin-unix AS bin-linux
FROM bin-unix AS bin-darwin

FROM scratch AS bin-windows
COPY --from=build /out/example /example.exe

FROM bin-${TARGETOS} as bin
