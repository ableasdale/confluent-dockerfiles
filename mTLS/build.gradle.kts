plugins {
    id("java")
    id("application")
}

group = "org.example"
version = "1.0-SNAPSHOT"

application {
    mainClass.set("io.confluent.csta.TLSProducer")
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(platform("org.junit:junit-bom:5.9.1"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    implementation("ch.qos.logback:logback-classic:1.2.11")
    implementation("org.apache.kafka:kafka-clients:3.4.0")
}

tasks.test {
    useJUnitPlatform()
}