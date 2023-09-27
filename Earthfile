VERSION 0.7
FROM crystallang/crystal:latest
WORKDIR /workdir

all:
    BUILD +test

deps:
    RUN apt-get update \
     && apt-get install -y gettext
    COPY . ./
    RUN shards install

test:
    FROM +deps
    RUN crystal spec
