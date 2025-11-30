#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>

// Wi-Fi credentials
const char* ssid = "ArafathMohammed";
const char* password = "yedhukku";

// AWS IoT Core endpoint
const char* mqtt_server = "a1nish8gdbwteu-ats.iot.ap-south-1.amazonaws.com";

// MQTT topics
const char* mqtt_topic_data = "emg/data";
const char* mqtt_topic_commands = "emg/commands";
const char* client_id = "ESP32_EMGsmall";

// Certificates
const char* root_ca = \
"-----BEGIN CERTIFICATE-----\n"\
"MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF\n"\
"ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6\n"\
"b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL\n"\
"MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv\n"\
"b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj\n"\
"ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM\n"\
"9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw\n"\
"IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6\n"\
"VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L\n"\
"93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm\n"\
"jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC\n"\
"AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA\n"\
"A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI\n"\
"U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs\n"\
"N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv\n"\
"o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU\n"\
"5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy\n"\
"rqXRfboQnoZsG4q5WTP468SQvvG5\n"\
"-----END CERTIFICATE-----\n";

const char* certificate = \
"-----BEGIN CERTIFICATE-----\n"\
"MIIDWTCCAkGgAwIBAgIUSpRBPEs7geUV93HvW0jVYgeGLbswDQYJKoZIhvcNAQEL\n"\
"BQAwTTFLMEkGA1UECwxCQW1hem9uIFdlYiBTZXJ2aWNlcyBPPUFtYXpvbi5jb20g\n"\
"SW5jLiBMPVNlYXR0bGUgU1Q9V2FzaGluZ3RvbiBDPVVTMB4XDTI1MDQxOTE0NDEy\n"\
"NVoXDTQ5MTIzMTIzNTk1OVowHjEcMBoGA1UEAwwTQVdTIElvVCBDZXJ0aWZpY2F0\n"\
"ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANxmfHUzd2IujR8TjpFJ\n"\
"mvjUWrHRIyr/U1G7QZfRj362Jb8+J7gayF6E01+XNPW7B6xt8AJHHIqw+MQji7SJ\n"\
"1h55mXdfokwsneVynZwt9PcvhmvrrNfPqha5wBx5KE0fuT3eFPAJ3/Yuj7dLRSth\n"\
"YQYI2sOJCelrW/QpkXE/XRXWiRZvD+Oz9uRLfY9qZu24aUB4AA3mYFImZMH0N8ce\n"\
"QFcbfW/rkq+01BhevQXLzi8lSchulQKX8VNSvktSSUfM+QgE3qcHPU/3kWPJtqnr\n"\
"kGn9vIR4QdPnLcZtsPLOsMAOSnocK/ykSdziue7plnXVmgovSDGYvIQYOwTlP2aA\n"\
"EN0CAwEAAaNgMF4wHwYDVR0jBBgwFoAUpxiXL/zqtzo4XENtw4gtdu3x2KgwHQYD\n"\
"VR0OBBYEFCsVPr17JfET9c9qzrxsIaF7mw5lMAwGA1UdEwEB/wQCMAAwDgYDVR0P\n"\
"AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQAOYwYqAXMjJ8ykfWTjHqz6UUYv\n"\
"pzL7zb940+hExOs2C9FkXCi6Y4gWJtr9RX+Sf8RnN2HWN+l9DTC1FryATMgJEUjB\n"\
"kIAC+3EVlI0vRfy9YvV1L32k9K2nb1X3xIpQCwTs1ia0KlTJMIskr9KFz5cQge1M\n"\
"DprKwPpLxBM3GQmYuwMLHsTa5k+rT6izJthpGrIP/oJNc1UrI+lujuqoqb+4V4UE\n"\
"xafprN9xk4UxYE0wTBG2TPKF7liP2io3EsnNQpmdnRQCX14ypDB2tKaZvLEs7MJD\n"\
"aZJSIM6Tl2uAwcxny39DbTTGr1h/XepcxfiIAjNGRwcEDg0jRPsbxdV+LYpQ\n"\
"-----END CERTIFICATE-----\n";

const char* private_key = \
"-----BEGIN RSA PRIVATE KEY-----\n"\
"MIIEpAIBAAKCAQEA3GZ8dTN3Yi6NHxOOkUma+NRasdEjKv9TUbtBl9GPfrYlvz4n\n"\
"uBrIXoTTX5c09bsHrG3wAkccirD4xCOLtInWHnmZd1+iTCyd5XKdnC309y+Ga+us\n"\
"18+qFrnAHHkoTR+5Pd4U8Anf9i6Pt0tFK2FhBgjaw4kJ6Wtb9CmRcT9dFdaJFm8P\n"\
"47P25Et9j2pm7bhpQHgADeZgUiZkwfQ3xx5AVxt9b+uSr7TUGF69BcvOLyVJyG6V\n"\
"ApfxU1K+S1JJR8z5CATepwc9T/eRY8m2qeuQaf28hHhB0+ctxm2w8s6wwA5Kehwr\n"\
"/KRJ3OK57umWddWaCi9IMZi8hBg7BOU/ZoAQ3QIDAQABAoIBAGbKMX9jqmkS9uQo\n"\
"ddRStMEaINZPiIxUGiLDJ5tLtBXPk5k2vsWBUDOs1Pv/BEcanECR4V7elXQlh0/K\n"\
"mCxyIHeEFMv0wTevk1BgfRtK37Ws549LkgfwpQ4GQY/F/cLCad1txuwQXvBs1MAS\n"\
"jcbmmp564LRTJFlFpdQg0uEzQRGeZ7NOms3BikpZ8ZxqwJPAoHc+EPNHYDpahvQx\n"\
"YeHlU2hS8egSpb4rf+0LKFoOz5a5Tz6pi8Ud+aUksR9725iOXVrOLhWD9dMwN+L0\n"\
"ebLDDdtGFnF1Q3/Ac3uhECLt1ba3UiM6JnIrQe+hLZ4gzacWqDjR35teCTM0L7zG\n"\
"wiUgBs0CgYEA/beM+2Sa0vxp1DolrDovB20o2dDKxquCKFCwRJZv+jrUi21IXB2K\n"\
"9lBB03mIHKmbpFgeDHS8Ogsa0iaMufoqEz2qNq2KpORTaRVuD63JTdMjZQXokxjc\n"\
"DhIOvHpjp5M5X0VsnrQgYauBQc+qUQeHdxAGWx3ODWjJILg1h/kn3kcCgYEA3mIw\n"\
"XaVYvn65VVKm+Z1Sp3g2Nq97cBfws+OdVWqyXfNIte6ZNtlP6nUxoVTs7wLA7w1T\n"\
"QHoCn2COGuUM5N+MQDH2z8cmJeZVvpilgLb+0VtcjRXRjG61bmJcZNzO5qm+uYRm\n"\
"+MO7KO/qiKLbkeruc4Vx909tz4jzXYffX9HENbsCgYEA4MVX9O8v6nMMHqRU87uo\n"\
"JmAirLU4r8EJ0kWJo3nTQlAUNGFglZrmnUiEyKEGYL4x0Orv1AEnMBTecgcM7UYf\n"\
"OGSNA1vDVEmjS5lcpC9GA9hlpv4RCSAg86Yzv+59ktvvG+QZUpApj92s6WzcamTN\n"\
"MkHUH6zL+z010fLgGdI168kCgYEAzI1Qo7LFkGOMIhlmkU/OiVCfvWloh1DeDPme\n"\
"7MS50IVJKl+P+s2lHqoxvo4ZajgEM170ZuhTpTnxPHfXhmbB4QKUXcZ3JoFZ+Xj7\n"\
"MwwgE36QAQ5Cs4PZyvEav4QDpFQapRZOiR+w9hTIjGoQwYVxVD04+RzMiwsTn8Kt\n"\
"CrwuWKUCgYAqirCKv9yAG9QbJoJGytzVflvLoZepdFU5k2sqrPPe+1KvNfFoEbGm\n"\
"4acw/lmue1LPmLcPD/9hK/XjaQt+H2Z9z7VnGxr3YhP1tlVy9sYMd5UYwQYbTv6W\n"\
"/ae8T/Kp0nhOIPMSfNjDohPxysdR7ne9yhptNmgHha160ms2wccBYw==\n"\
"-----END RSA PRIVATE KEY-----\n";

// Motor Control Pins
#define M1_IN1 27
#define M1_IN2 26
#define M1_ENA 14
#define M2_IN1 25
#define M2_IN2 33
#define M2_ENB 32
#define M3_IN1 19
#define M3_IN2 18
#define M3_ENA 5
#define M4_IN1 17
#define M4_IN2 16
#define M4_ENB 4

// PWM Channels
#define M1_PWM_CH 0
#define M2_PWM_CH 1
#define M3_PWM_CH 2
#define M4_PWM_CH 3

// BIOAMP EXG Pill analog input
#define EMG_PIN 34

// EMG Sampling and Windowing
#define SAMPLE_RATE_HZ 10000
#define WINDOW_SIZE 10000      // 1 second at 10kHz
#define OVERLAP 5000           // 50% overlap

WiFiClientSecure wifiClient;
PubSubClient client(wifiClient);

// Helper function to run/stop a motor
void runMotor(int in1, int in2, int pwm_ch, bool run) {
  if (run) {
    digitalWrite(in1, HIGH);
    digitalWrite(in2, LOW);
    ledcWrite(pwm_ch, 255); // Full speed
  } else {
    digitalWrite(in1, LOW);
    digitalWrite(in2, LOW);
    ledcWrite(pwm_ch, 0);   // Stop
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i=0; i<length; i++) message += (char)payload[i];
  Serial.print("Command received: "); Serial.println(message);

  if (message == "G") { // Grip: all motors
    runMotor(M1_IN1, M1_IN2, M1_PWM_CH, true);
    runMotor(M2_IN1, M2_IN2, M2_PWM_CH, true);
    runMotor(M3_IN1, M3_IN2, M3_PWM_CH, true);
    runMotor(M4_IN1, M4_IN2, M4_PWM_CH, true);
  } else if (message == "T") { // Tripod: motors 1,2,3
    runMotor(M1_IN1, M1_IN2, M1_PWM_CH, true);
    runMotor(M2_IN1, M2_IN2, M2_PWM_CH, true);
    runMotor(M3_IN1, M3_IN2, M3_PWM_CH, true);
    runMotor(M4_IN1, M4_IN2, M4_PWM_CH, false);
  } else if (message == "P") { // Pinch: motors 1,2
    runMotor(M1_IN1, M1_IN2, M1_PWM_CH, true);
    runMotor(M2_IN1, M2_IN2, M2_PWM_CH, true);
    runMotor(M3_IN1, M3_IN2, M3_PWM_CH, false);
    runMotor(M4_IN1, M4_IN2, M4_PWM_CH, false);
  } else { // Stop all
    runMotor(M1_IN1, M1_IN2, M1_PWM_CH, false);
    runMotor(M2_IN1, M2_IN2, M2_PWM_CH, false);
    runMotor(M3_IN1, M3_IN2, M3_PWM_CH, false);
    runMotor(M4_IN1, M4_IN2, M4_PWM_CH, false);
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    if (client.connect(client_id)) {
      Serial.println("connected");
      client.subscribe(mqtt_topic_commands);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 5s");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);

  // Motor pin setup
  pinMode(M1_IN1, OUTPUT); pinMode(M1_IN2, OUTPUT);
  pinMode(M2_IN1, OUTPUT); pinMode(M2_IN2, OUTPUT);
  pinMode(M3_IN1, OUTPUT); pinMode(M3_IN2, OUTPUT);
  pinMode(M4_IN1, OUTPUT); pinMode(M4_IN2, OUTPUT);

  // PWM setup
  ledcSetup(M1_PWM_CH, 5000, 8); ledcAttachPin(M1_ENA, M1_PWM_CH);
  ledcSetup(M2_PWM_CH, 5000, 8); ledcAttachPin(M2_ENB, M2_PWM_CH);
  ledcSetup(M3_PWM_CH, 5000, 8); ledcAttachPin(M3_ENA, M3_PWM_CH);
  ledcSetup(M4_PWM_CH, 5000, 8); ledcAttachPin(M4_ENB, M4_PWM_CH);

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\nConnected!");

  // Certificates
  wifiClient.setCACert(root_ca);
  wifiClient.setCertificate(certificate);
  wifiClient.setPrivateKey(private_key);

  // MQTT
  client.setServer(mqtt_server, 8883);
  client.setCallback(mqttCallback);
}

int emg_buffer[WINDOW_SIZE];
int idx = 0;

void loop() {
  // WiFi stability check
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected! Reconnecting...");
    WiFi.disconnect();
    WiFi.reconnect();
    delay(2000);
    return; // Skip publishing until reconnected
  }

  // MQTT connection check
  if (!client.connected()) reconnect();
  client.loop();

  // EMG Sampling at 10kHz
  emg_buffer[idx++] = analogRead(EMG_PIN);

  if (idx == WINDOW_SIZE) {
    // Build JSON array
    String payload = "{\"emg_data\":[";
    for (int i = 0; i < WINDOW_SIZE; i++) {
      payload += String(emg_buffer[i]);
      if (i < WINDOW_SIZE - 1) payload += ",";
    }
    payload += "]}";
    client.publish(mqtt_topic_data, payload.c_str());

    // Overlap: move last OVERLAP samples to front
    for (int i = 0; i < OVERLAP; i++) {
      emg_buffer[i] = emg_buffer[WINDOW_SIZE - OVERLAP + i];
    }
    idx = OVERLAP;
  }

  delayMicroseconds(100); // 10,000 Hz sampling
}
