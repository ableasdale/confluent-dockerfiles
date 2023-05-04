#!/bin/bash
set -euf -o pipefail

VALIDITY=365
PASSWORD="confluent"

echo "Creating root Certificate (CA)"
openssl req -new -newkey rsa:4096 -days $VALIDITY -x509 -subj "/CN=Kafka-Security-CA" -keyout ca-key -out ca-cert -nodes

for i in client broker control-center metrics schema-registry kafka-tools rest-proxy; do
	echo "Creating security materials for ${i}"
    echo "- ${i}: Keystore"
    keytool -genkey -keystore $i.keystore.jks -validity $VALIDITY -storepass $PASSWORD -keypass $PASSWORD -dname "CN=${i}" -storetype pkcs12 -keyalg RSA
    echo "- ${i}: Adding Certificate to Keystore"
    keytool -keystore $i.keystore.jks -certreq -file $i.csr -storepass $PASSWORD -keypass $PASSWORD
    echo "- ${i}: Sign Server Certificate"
    openssl x509 -req -CA ca-cert -CAkey ca-key -in $i.csr -out $i-signed.crt -days $VALIDITY -CAcreateserial -passin pass:$PASSWORD
    echo "- ${i}: Import the signed client certificate and the CA into the keystore"
    keytool -keystore $i.keystore.jks -alias CARoot -import -file ca-cert -storepass $PASSWORD -keypass $PASSWORD -noprompt
    echo "- ${i}: Add Certificate Reply"
    keytool -keystore $i.keystore.jks -import -file $i-signed.crt -storepass $PASSWORD -keypass $PASSWORD -noprompt
    echo "- ${i}: Truststore"
    keytool -keystore $i.truststore.jks -alias CARoot -import -file ca-cert -storepass $PASSWORD -keypass $PASSWORD -noprompt -keyalg RSA    
    echo "- ${i}: Create credentials files"
    echo $PASSWORD >${i}_sslkey_creds
	echo $PASSWORD >${i}_keystore_creds
	echo $PASSWORD >${i}_truststore_creds
done

echo "Creating PEM File"
cat ca-cert ca-key > ca.pem

echo "✅  All done."