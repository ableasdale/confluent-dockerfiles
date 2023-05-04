FROM ubuntu:23.04

ENV CONFLUENT_HOME=/usr \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/ \
    TERM=xterm-256color

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
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


# E NV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/
# RUN export JAVA_HOME

#/usr/lib/jvm/java-17-openjdk-amd64/bin



#If your base image contains by default OpenJDK and If you want to use OracleJDK in your image just add the below command to your dockerfile and build the image and boom your image will have oracle JDK.

#RUN yum -y remove java***
 #   echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")" | tee 
##RUN yum localinstall -y jdk-8u212-linux-x64.rpm && \
  #  -a /etc/profile && source /etc/profile && echo $JAVA_HOME && \
   # rm jdk-8u212-linux-x64.rpm && \ 
    #alternatives --set java /usr/java/jdk1.8.0_212-amd64/jre/bin/java
# /usr/lib/jvm/java-17-openjdk-amd64/