VERSION 0.7
FROM 84codes/crystal:latest-ubuntu-22.04
WORKDIR /workdir

# ci runs only in CI
ci:
    BUILD +lint
    BUILD --platform=linux/amd64 +test
    BUILD --platform=linux/arm64 +test

# deps adds source code and builds project dependency graph
deps:
    RUN apt-get update \
     && apt-get install -y gettext
    COPY . ./
    RUN shards install

# test executes project specs
test:
    FROM +deps
    RUN crystal spec

# lint executes ameba
lint:
    FROM ghcr.io/crystal-ameba/ameba:1.5.0
    COPY . ./
    RUN ameba
