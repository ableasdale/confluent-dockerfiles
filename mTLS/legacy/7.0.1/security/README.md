```
❯ openssl req -new -x509 -keyout ca-key -out ca-cert -days 7
Generating a RSA private key
..................................+++++
.+++++
writing new private key to 'ca-key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:Ca
Locality Name (eg, city) []:PaoloAlto
Organization Name (eg, company) [Internet Widgits Pty Ltd]:CONFLUENT
Organizational Unit Name (eg, section) []:TEST
Common Name (e.g. server FQDN or YOUR name) []:Confluent
Email Address []:
```
2.
```
❯ keytool -keystore zookeeper.server.keystore.jks -alias zookeeper -validity 7 -genkey -dname "CN=zookeeper,OU=TEST,O=CONFLUENT,L=PaoloAlto,S=Ca,C=US" -keyalg RSA
Enter keystore password:
Re-enter new password:
```
3.
```
❯ keytool -keystore zookeeper.server.keystore.jks -alias zookeeper -certreq -file zookeeper-cert-file
Enter keystore password:
```

4.
```
❯ openssl x509 -req -CA ca-cert -CAkey ca-key -in zookeeper-cert-file -out zookeeper-cert-signed -days 7 -CAcreateserial -passin pass:testtest
Signature ok
subject=C = US, ST = Ca, L = PaoloAlto, O = CONFLUENT, OU = TEST, CN = zookeeper
Getting CA Private Key
```

5.
```
❯ keytool -keystore zookeeper.server.keystore.jks -alias CARoot -importcert -file ca-cert
Enter keystore password:
Owner: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Issuer: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Serial number: 459a6739f1e0594bb3cc4d35a8f18e1b36b4dfef
Valid from: Thu Mar 24 15:21:25 GMT 2022 until: Thu Mar 31 16:21:25 BST 2022
Certificate fingerprints:
	 SHA1: ED:AE:D8:EF:BB:4F:FC:99:8C:32:B4:F0:9D:72:2E:47:F3:50:0C:1C
	 SHA256: 69:5F:CB:04:C2:70:CA:26:8F:ED:EC:66:D6:7D:75:EE:3E:90:7D:3F:83:D6:A0:3A:7B:F1:E6:62:EE:07:29:90
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen:2147483647
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

Trust this certificate? [no]:  yes
Certificate was added to keystore
```

6.
```
❯ keytool -keystore zookeeper.server.keystore.jks -alias localhost -importcert -file zookeeper-cert-signed
Enter keystore password:
Certificate was added to keystore
```

7.
```
❯ keytool -keystore zookeeper.server.truststore.jks -alias CARoot -importcert -file ca-cert
Enter keystore password:
Re-enter new password:
Owner: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Issuer: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Serial number: 459a6739f1e0594bb3cc4d35a8f18e1b36b4dfef
Valid from: Thu Mar 24 15:21:25 GMT 2022 until: Thu Mar 31 16:21:25 BST 2022
Certificate fingerprints:
	 SHA1: ED:AE:D8:EF:BB:4F:FC:99:8C:32:B4:F0:9D:72:2E:47:F3:50:0C:1C
	 SHA256: 69:5F:CB:04:C2:70:CA:26:8F:ED:EC:66:D6:7D:75:EE:3E:90:7D:3F:83:D6:A0:3A:7B:F1:E6:62:EE:07:29:90
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen:2147483647
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

Trust this certificate? [no]:  yes
Certificate was added to keystore
```

## Broker
1
```
❯ keytool -keystore broker.server.keystore.jks -alias broker -validity 7 -genkey -dname "CN=broker,OU=TEST,O=CONFLUENT,L=PaoloAlto,S=Ca,C=US" -keyalg RSA
Enter keystore password:
Re-enter new password:
```

2
```
❯ keytool -keystore broker.server.keystore.jks -alias broker -certreq -file broker-cert-file
Enter keystore password:
```

3.
```
❯ openssl x509 -req -CA ca-cert -CAkey ca-key -in broker-cert-file -out broker-cert-signed -days 7 -CAcreateserial -passin pass:testtest
Signature ok
subject=C = US, ST = Ca, L = PaoloAlto, O = CONFLUENT, OU = TEST, CN = broker
Getting CA Private Key
```

4.
```
❯ keytool -keystore broker.server.keystore.jks -alias CARoot -importcert -file ca-cert
Enter keystore password:
Owner: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Issuer: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Serial number: 459a6739f1e0594bb3cc4d35a8f18e1b36b4dfef
Valid from: Thu Mar 24 15:21:25 GMT 2022 until: Thu Mar 31 16:21:25 BST 2022
Certificate fingerprints:
	 SHA1: ED:AE:D8:EF:BB:4F:FC:99:8C:32:B4:F0:9D:72:2E:47:F3:50:0C:1C
	 SHA256: 69:5F:CB:04:C2:70:CA:26:8F:ED:EC:66:D6:7D:75:EE:3E:90:7D:3F:83:D6:A0:3A:7B:F1:E6:62:EE:07:29:90
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen:2147483647
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

Trust this certificate? [no]:  y
Certificate was added to keystore
```
5. 

```
❯ keytool -keystore broker.server.keystore.jks -alias localhost -importcert -file broker-cert-signed
Enter keystore password:
Certificate was added to keystore
```

6.
```
❯ keytool -keystore broker.server.truststore.jks -alias CARoot -importcert -file ca-cert
Enter keystore password:
Re-enter new password:
Owner: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Issuer: CN=Confluent, OU=TEST, O=CONFLUENT, L=PaoloAlto, ST=Ca, C=US
Serial number: 459a6739f1e0594bb3cc4d35a8f18e1b36b4dfef
Valid from: Thu Mar 24 15:21:25 GMT 2022 until: Thu Mar 31 16:21:25 BST 2022
Certificate fingerprints:
	 SHA1: ED:AE:D8:EF:BB:4F:FC:99:8C:32:B4:F0:9D:72:2E:47:F3:50:0C:1C
	 SHA256: 69:5F:CB:04:C2:70:CA:26:8F:ED:EC:66:D6:7D:75:EE:3E:90:7D:3F:83:D6:A0:3A:7B:F1:E6:62:EE:07:29:90
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen:2147483647
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 8B CF 34 30 96 AF 8B 71   14 BA 63 72 25 77 00 E7  ..40...q..cr%w..
0010: 49 9C E3 A8                                        I...
]
]

Trust this certificate? [no]:  y
Certificate was added to keystore
```

