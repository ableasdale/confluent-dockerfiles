echo "Step 1: Root Certificate (CA)"
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout ca-key -out ca-cert -nodes
# Broker
echo "Step 2: Server Keystore"
keytool -genkey -keystore kafka.server.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=broker" -ext san=dns:localhost -storetype pkcs12 -keyalg RSA
echo "Step 3: Adding Certificate to Keystore"
keytool -keystore kafka.server.keystore.jks -certreq -file cert-file -storepass confluent -keypass confluent
echo "Step 4: Sign Server Certificate"
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo "Step 5: Server Truststore"
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo "Step 6: Import the signed client certificate and the CA into the keystore"
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt
echo "Step 7: Add Certificate Reply"
keytool -keystore kafka.server.keystore.jks -import -file cert-signed -storepass confluent -keypass confluent -noprompt
echo "Step 8: Create credentials file"
tee broker_sslkey_creds << EOF >/dev/null
confluent
EOF
# Client
echo "Step 9: Client Truststore"
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo "Step 10: Client Keystore"
keytool -genkey -keystore kafka.client.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=broker" -ext san=dns:localhost -alias my-local-pc -storetype pkcs12 -keyalg RSA
echo "Step 11: Client Cert signing request"
keytool -keystore kafka.client.keystore.jks -certreq -file client-cert-sign-request -alias my-local-pc -storepass confluent -keypass confluent
echo "Step 12: Sign Client Certificate"
openssl x509 -req -CA ca-cert -CAkey ca-key -in client-cert-sign-request -out client-cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo "Step 13: Import the signed client certificate and the CA into the keystore"
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt
echo "Step 13: Add Certificate Reply"
keytool -keystore kafka.client.keystore.jks -import -file client-cert-signed -alias my-local-pc -storepass confluent -keypass confluent -noprompt
# SR
echo "Step 14: Schema Registry Truststore"
keytool -keystore schema-registry.truststore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo "Step 15: Schema Registry Keystore"
keytool -genkey -keystore schema-registry.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=schemaregistry" -alias my-local-pc -storetype pkcs12 -keyalg RSA
echo "Step 16: Schema Registry Cert signing request"
keytool -keystore schema-registry.keystore.jks -certreq -file schema-registry-sign-request -alias my-local-pc -storepass confluent -keypass confluent
echo "Step 17: Sign Schema Registry Certificate"
openssl x509 -req -CA ca-cert -CAkey ca-key -in schema-registry-sign-request -out schema-registry-cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo "Step 18: Import the signed Schema Registry certificate and the CA into the keystore"
keytool -keystore schema-registry.keystore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt
echo "Step 19: Add Certificate Reply"
keytool -keystore schema-registry.keystore.jks -import -file schema-registry-cert-signed -alias my-local-pc -storepass confluent -keypass confluent -noprompt

echo "Step 20: Create PEM File"
cat ca-cert ca-key > ca.pem