echo 1
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout ca-key -out ca-cert -nodes
echo 2
keytool -genkey -keystore kafka.server.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=broker1" -storetype pkcs12 -keyalg RSA
echo 3
keytool -keystore kafka.server.keystore.jks -certreq -file cert-file -storepass confluent -keypass confluent
echo 4
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo 5
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo 6
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt
echo 7
keytool -keystore kafka.server.keystore.jks -import -file cert-signed -storepass confluent -keypass confluent -noprompt