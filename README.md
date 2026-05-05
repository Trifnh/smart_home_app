# 🏠 Smart Home App

A modern **Flutter-based Smart Home application** integrated with **Firebase Realtime Database** and a simulated **IoT Hub (Raspberry Pi / ESP32)**.
The app enables real-time monitoring, device control, and scalable sensor configuration per room.

---

## 🚀 Features

### 🔌 Device Control

* Toggle devices (fan, lights, etc.) in real time
* Sync state across multiple screens (Dashboard ↔ Devices)
* Firebase + MQTT-ready architecture

### 🌡️ Sensor Monitoring

* Live temperature & humidity updates
* Room-based sensor visualization
* Scalable design for multiple sensor types

### 🧠 Dynamic Sensor Configuration

* Enable/disable sensors per room
* Add custom sensors (label + unit)
* Config stored in Firebase and consumed by IoT Hub

### 🎤 Voice Command (Experimental)

* Send commands via app → Firebase
* Processed by Raspberry Pi (NLP layer)
* Returns result back to app

### 📡 Real-time Sync Architecture

```text
Flutter App ↔ Firebase ↔ Raspberry Pi ↔ ESP32 (sensors/devices)
```

---

## 🏗️ Project Structure

```text
lib/
├── data/           # Static configs (device catalog)
├── models/         # Data models (automation rules, etc.)
├── navigation/     # App navigation (shell, tabs)
├── screens/        # UI screens (dashboard, devices, etc.)
├── services/       # Firebase + MQTT services
├── theme/          # App theme & styling
├── widgets/        # Reusable UI components
```

---

## 🔥 Firebase Structure (Simplified)

```json
{
  "rooms": {
    "living": {
      "devices": { "fan": true },
      "sensor_config": { "temperature": { "enabled": true } },
      "sensors": { "temperature": 29.5 }
    }
  },
  "devices": {
    "fan": { "status": true, "roomId": "living" }
  },
  "sensors": {
    "temperature": 29.2
  }
}
```

---

## ⚙️ Setup & Installation

### 1. Clone project

```bash
git clone <your-repo-url>
cd smart_home_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Setup Firebase

* Create project on Firebase Console
* Enable **Realtime Database**
* Download `google-services.json` (Android)
* Run:

```bash
flutterfire configure
```

---

## ▶️ Run App

### Run on Emulator / Device

```bash
flutter run
```

### Build APK

```bash
flutter build apk --release
```

---

## 🧪 Simulate IoT Hub (Python)

Use a Python script (`fake_pi.py`) to simulate sensor data:

```bash
python fake_pi.py
```

This will:

* Publish temperature & humidity
* Sync device state
* Update room sensors based on config

---

## 📱 Supported Platforms

* ✅ Android
* ✅ Web (basic)
* ✅ Windows (desktop testing)

---

## 🧠 Architecture Notes

* Firebase acts as **real-time sync layer**
* Raspberry Pi acts as:

  * Sensor aggregator
  * Automation engine
  * MQTT bridge (future)

### Recommended Production Upgrade

* Replace direct Firebase writes with:

```text
ESP32 → MQTT → Pi → Firebase
```

---

## 🛠️ Tech Stack

* Flutter (UI)
* Firebase Realtime Database
* Provider (state management)
* Python (IoT simulation)
* MQTT (planned integration)

---

## 📌 Roadmap

* [ ] Dynamic sensor UI (auto-render from config)
* [ ] Automation rule engine (Pi side)
* [ ] MQTT integration (ESP32)
* [ ] Push notifications
* [ ] User roles & permissions

---

## 🤝 Contributing

Contributions are welcome. Feel free to:

* Open issues
* Submit pull requests
* Suggest improvements

---

## 📄 License

This project is for educational and research purposes.

---

## 👨‍💻 Author

Developed as part of a Capstone / IoT Smart Home system project.