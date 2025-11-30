#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>



// Wi-Fi credentials
const char* ssid = "ArafathMohammed";
const char* password = "yedhukku";

// AWS IoT Core endpoint (found in AWS IoT console)
const char* mqtt_server = "a1nish8gdbwteu-ats.iot.ap-south-1.amazonaws.com";

// MQTT topics
const char* mqtt_topic_data = "emg/data";
const char* mqtt_topic_commands = "emg/commands";

// Unique client ID for MQTT connection
const char* client_id = "ESP32_ProstheticController";

// Paths to your AWS IoT certificates (upload these to your ESP32 filesystem or embed)
const char* certificate = "D:/MIT/Main project/Prosthetic hand/AWS certificate/ESP32_EMGsmall/ESP32_EMGsmall-Device certificate.pem.crt";
const char* private_key = "D:/MIT/Main project/Prosthetic hand/AWS certificate/ESP32_EMGsmall/ESP32_EMGsmall-Private key.key";
const char* root_ca = "D:/MIT/Main project/Prosthetic hand/AWS certificate/ESP32_EMGsmall/ESP32_EMGsmall-RootCA1.pem";



WiFiClientSecure wifiClient;
PubSubClient client(wifiClient);



void setup() {
  Serial.begin(115200);
  
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected!");
  
  // Configure certificates for secure MQTT connection
  wifiClient.setCACert(root_ca);
  wifiClient.setCertificate(certificate);
  wifiClient.setPrivateKey(private_key);
  
  client.setServer(mqtt_server, 8883);
  while (!client.connected()) {
        if (client.connect(client_id)) {
            Serial.println("Connected to AWS IoT!");
        } else {
            delay(2000);
        }
    }
}

void loop() {
    int emg_data = analogRead(34);  // Replace with actual sensor pin
    String payload = "{\"emg_data\": " + String(emg_data) + "}";
    client.publish(mqtt_topic_data, payload.c_str());
    client.loop();
}
