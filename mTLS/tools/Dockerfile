FROM ubuntu:23.04

ENV CONFLUENT_HOME=/usr \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/ \
    TERM=xterm-256color

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        dig \
        openssl \
        curl \
        wget \
        jq \
        netcat-openbsd \
        httpie \
        peco \
        vim \
        expect \
        openjdk-17-jdk \
        gradle \
        kafkacat \
    && curl --http1.1 -L https://cnfl.io/cli | sh -s -- -b /usr/bin v3.11.0 \
    && rm -rf /var/lib/apt/lists/*
