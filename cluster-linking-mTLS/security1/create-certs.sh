echo "Step 1: Root Certificate (CA)"
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout ca-key -out ca-cert -nodes

echo "Step 2: Server Keystore"
keytool -genkey -keystore kafka.server.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=broker1" -storetype pkcs12 -keyalg RSA
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
echo "Step 9: Client Truststore"
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt -keyalg RSA
echo "Step 10: Client Keystore"
keytool -genkey -keystore kafka.client.keystore.jks -validity 365 -storepass confluent -keypass confluent -dname "CN=broker1" -alias my-local-pc -storetype pkcs12 -keyalg RSA
echo "Step 11: Client Cert signing request"
keytool -keystore kafka.client.keystore.jks -certreq -file client-cert-sign-request -alias my-local-pc -storepass confluent -keypass confluent
echo "Step 12: Sign Client Certificate"
openssl x509 -req -CA ca-cert -CAkey ca-key -in client-cert-sign-request -out client-cert-signed -days 365 -CAcreateserial -passin pass:confluent
echo "Step 13: Import the signed client certificate and the CA into the keystore"
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -storepass confluent -keypass confluent -noprompt
echo "Step 13: Add Certificate Reply"
keytool -keystore kafka.client.keystore.jks -import -file client-cert-signed -alias my-local-pc -storepass confluent -keypass confluent -noprompt
echo "Step 14: Create PEM File"
cat ca.crt ca.key > ca.pem