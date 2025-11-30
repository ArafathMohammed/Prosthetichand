import ssl
import json
import numpy as np
import pywt
from scipy.signal import stft
from scipy.signal.windows import hamming
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler
import joblib
import paho.mqtt.client as mqtt
from collections import deque

# --- Load model and scaler ---
model = joblib.load('trained_ann_model.pkl')
scaler = joblib.load('scaler.pkl')

# --- MQTT Settings ---
AWS_IOT_ENDPOINT = "a1nish8gdbwteu-ats.iot.ap-south-1.amazonaws.com"  # <-
CA_PATH = "ESP32_EMGsmall-RootCA1.pem"
CERT_PATH = "ESP32_EMGsmall-Device certificate.pem.crt"      # <-- your device certificate
KEY_PATH = "ESP32_EMGsmall-Private key.key"                  # <-- your private key
MQTT_TOPIC_DATA = "emg/data"
MQTT_TOPIC_COMMANDS = "emg/commands"

# --- Signal Processing Parameters ---
WINDOW_SIZE = 10000  # Must match your model's expected input size
OVERLAP = 5000       # 50% overlap
buffer = deque(maxlen=WINDOW_SIZE + OVERLAP)  # Buffer for accumulating samples

# --- Signal Processing Functions (as in your code) ---
def vmd(signal, num_imf=5, alpha=1000, tol=1e-7, max_iter=500):
    signal = np.asarray(signal).flatten()
    N = len(signal)
    f_mirror = np.concatenate([signal[::-1], signal, signal[::-1]])
    T = len(f_mirror)
    omega = np.fft.fftshift(np.fft.fftfreq(T, d=1.0))
    f_hat = np.fft.fftshift(np.fft.fft(f_mirror))
    u_hat = np.zeros((num_imf, T), dtype=complex)
    omega_k = np.linspace(0, 0.5, num_imf)
    lambda_hat = np.zeros(T, dtype=complex)
    for it in range(max_iter):
        u_hat_prev = u_hat.copy()
        for k in range(num_imf):
            sum_others = np.sum(u_hat, axis=0) - u_hat[k]
            rhs = f_hat - sum_others - lambda_hat/2
            denom = 1 + 2*alpha*(omega - omega_k[k])**2
            u_hat[k] = rhs / denom
            omega_k[k] = np.sum(np.abs(omega) * np.abs(u_hat[k])**2) / (np.sum(np.abs(u_hat[k])**2) + 1e-10)
        lambda_hat += 2 * (np.sum(u_hat, axis=0) - f_hat)
        if np.linalg.norm(u_hat - u_hat_prev) / (np.linalg.norm(u_hat_prev) + 1e-10) < tol:
            break
    imfs = np.zeros((num_imf, N))
    for k in range(num_imf):
        u_temp = np.fft.ifft(np.fft.ifftshift(u_hat[k])).real
        imfs[k] = u_temp[N:2*N]
    return imfs.T

def calculate_snr(imf):
    signal_power = np.mean(imf**2)
    threshold = 0.05 * np.max(np.abs(imf))
    noise = imf[np.abs(imf) < threshold]
    noise_power = np.mean(noise**2) if len(noise) > 0 else 1e-10
    return 10 * np.log10(signal_power / noise_power)

def extract_features(imf, fs=10000):
    mean_val = np.mean(imf)
    std_val = np.std(imf)
    rms_val = np.sqrt(np.mean(imf**2))
    zero_crossings = np.sum(np.diff(np.sign(imf)) != 0)
    features = [mean_val, std_val, rms_val, zero_crossings]
    scales = np.arange(1, 31)
    coeffs, _ = pywt.cwt(imf, scales, 'morl', sampling_period=1/fs)
    energy_wavelet = np.sum(np.abs(coeffs)**2, axis=1)
    features.extend(energy_wavelet)
    window_size = int(fs * 0.1)
    overlap = int(window_size * 0.5)
    _, _, Zxx = stft(imf, fs=fs, window=hamming(window_size),
                     nperseg=window_size, noverlap=overlap, nfft=max(1024, window_size))
    psd = np.abs(Zxx)**2
    mean_psd = np.mean(psd, axis=1)
    features.extend(mean_psd)
    return np.array(features)

def process_emg_signal(emg_signal):
    imfs = vmd(emg_signal, num_imf=5)
    snr_values = [calculate_snr(imfs[:, k]) for k in range(imfs.shape[1])]
    best_imf = imfs[:, np.argmax(snr_values)]
    features = extract_features(best_imf, fs=10000)
    features = features.reshape(1, -1)
    features = scaler.transform(features)
    prediction = model.predict(features)
    return int(prediction[0])

# --- MQTT Callbacks ---
def on_connect(client, userdata, flags, rc):
    print("Connected with result code", rc)
    client.subscribe(MQTT_TOPIC_DATA)

def on_message(client, userdata, msg):
    print(f"Received message on {msg.topic}")
    try:
        payload = json.loads(msg.payload.decode())
        emg_data = payload.get("emg_data")
        
        if isinstance(emg_data, list):
            # Add new samples to buffer
            buffer.extend(emg_data)
            print(f"Buffer size: {len(buffer)}/{WINDOW_SIZE}")
            
            # Process when we have enough samples
            while len(buffer) >= WINDOW_SIZE:
                window = np.array(list(buffer)[:WINDOW_SIZE], dtype=np.float32)
                action = process_emg_signal(window)
                
                # Send command
                command_map = {0: "G", 1: "P", 2: "T"}
                command = command_map.get(action, "G")
                client.publish(MQTT_TOPIC_COMMANDS, command)
                print(f"Published command: {command}")
                
                # Maintain overlap for continuous processing
                for _ in range(WINDOW_SIZE - OVERLAP):
                    if buffer:
                        buffer.popleft()
        else:
            print("Invalid data format")
            
    except Exception as e:
        print("Error processing message:", e)

# --- MQTT Client Setup ---
client = mqtt.Client()
client.tls_set(ca_certs=CA_PATH, certfile=CERT_PATH, keyfile=KEY_PATH, 
               tls_version=ssl.PROTOCOL_TLSv1_2)
client.on_connect = on_connect
client.on_message = on_message

client.connect(AWS_IOT_ENDPOINT, 8883, 60)
client.loop_forever()
