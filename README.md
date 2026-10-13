# PDF Studio Pro 📄✨

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-5.0%2B-3DDC84?logo=android)](https://developer.android.com)

**PDF Studio Pro** is a modern, fast, and feature-rich Android PDF application built with Flutter. It lets you view, annotate, digitally sign, stamp, and share documents effortlessly across all your mobile workflows.

---

## 🌟 Key Features

- 📑 **Comprehensive PDF Viewer**
  - Smooth vertical & horizontal scrolling
  - Pinch-to-zoom with crisp vector rendering
  - Page jump and real-time page indicator
  - Built-in sample documents (Invoice, Non-Disclosure Agreement)

- ✍️ **Digital Signatures & Stamps**
  - Draw custom freehand signatures with variable stroke width and colors
  - Save signatures to your reusable digital vault
  - Interactive signature placement (drag, resize, and position on any page)
  - Built-in verified digital approval stamps (APPROVED, CONFIDENTIAL, REVIEWED, REJECTED)

- 📝 **Annotations & Document Markup**
  - Text notes and freeform annotations
  - Highlight and markup important sections

- 💬 **Direct Opening from WhatsApp & WhatsApp Business**
  - Tap any received PDF document in WhatsApp or WhatsApp Business to open it directly into the viewer
  - System "Open with..." and "Share to..." integration with deep `ACTION_VIEW` & `ACTION_SEND` intent handling
  - Automatic sandboxed `ContentResolver` stream decryption and caching

- 🚀 **Cross-App & Device Sharing**
  - Instant sharing via WhatsApp, WhatsApp Business, Gmail, Outlook, Telegram, Bluetooth, and nearby devices
  - Clean export of signed and annotated PDF copies

- 📦 **Standalone Optimized Output**
  - Packaged as clean standalone APK: `PDFStudioPro.apk`

---

## 🛠️ Architecture

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **PDF Engine**: [pdf](https://pub.dev/packages/pdf) & [flutter_pdfview](https://pub.dev/packages/flutter_pdfview)
- **Platform Channel**: Native Android Intent Bridge (`MainActivity.kt`) communicating via `MethodChannel("com.antigravity.pdfreader/intent")`
- **Sharing**: [share_plus](https://pub.dev/packages/share_plus) & [file_picker](https://pub.dev/packages/file_picker)

---

## 🚀 Building & Running

### Prerequisites
- Flutter SDK (3.x or newer)
- Android SDK (API 34+)
- Java 17+

### Getting Started
```bash
# Clone the repository
git clone https://github.com/oktamatija/pdfstudiopro.git
cd pdfstudiopro

# Fetch dependencies
flutter pub get

# Run unit & widget tests
flutter test

# Run on connected Android device
flutter run

# Build release APK
flutter build apk --release
```
The compiled output is located at:
`build/app/outputs/flutter-apk/PDFStudioPro.apk`

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.  
See the [LICENSE](LICENSE) file for complete details.
