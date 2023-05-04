FROM  confluentinc/cp-server:7.4.0

USER root
# Set up a user to run Kafka
RUN groupadd kafka && \
  useradd -d /kafka -g kafka -s /bin/false kafka && \
  chown -R kafka:kafka /usr/bin/

USER kafka
ENV PATH /usr/bin:$PATH
WORKDIR /usr/bin