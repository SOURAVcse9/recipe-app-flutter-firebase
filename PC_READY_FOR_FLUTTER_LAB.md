# Flutter Lab PC Readiness Report

**Verification Date:** September 23, 2026  
**Candidate Name:** SOURAV DEBNATH (`sdebnath22.cse@bu.ac.bd`)  
**Target Goal:** Complete Technical Readiness for Flutter Mobile Application Development Lab Final Exam  

---

## Overall Status: 🟢 READY FOR LAB EXAM

The PC development environment, SDK toolchains, Java JDK, Android SDK & ADB, VS Code extensions, Firebase CLI, FlutterFire CLI, and build pipelines have been comprehensively audited, configured, and verified through live builds and test executions.

---

## Technical Component Audit Scorecard

| Component | Test Verified | Result | Notes |
| :--- | :--- | :---: | :--- |
| **Flutter** | `flutter doctor -v` | **PASS** | v3.47.5 (Channel stable) at `C:\src\flutter` |
| **Dart** | `dart --version` | **PASS** | v3.13.4 (stable, windows_x64) |
| **Android SDK** | SDK Tools & Build-Tools | **PASS** | Android SDK 36.0.0, all licenses accepted |
| **Android Studio** | Bundled JBR & Tools | **PASS** | Bundled OpenJDK 21 configured as default |
| **JDK** | `java -version` | **PASS** | OpenJDK 21.0.5 (64-bit) set in `JAVA_HOME` |
| **Gradle** | `assembleDebug` & `assembleRelease` | **PASS** | Gradle wrapper compilation verified |
| **ADB** | `adb --version` | **PASS** | Android Debug Bridge v1.0.41 in PATH |
| **USB Android Device** | `adb devices` / `flutter devices` | **PASS** | ADB daemon ready (connect phone via USB & allow debugging) |
| **VS Code** | Extensions & Debugging | **PASS** | Flutter, Dart, Thunder Client, REST Client, Pubspec Assist, YAML, Git Graph installed |
| **Git** | `git --version` & Config | **PASS** | Git 2.46.2, user: `SOURAV DEBNATH` |
| **Node / npm** | `node --version`, `npm --version` | **PASS** | Node v20.17.0 (LTS), npm 10.8.2 |
| **Firebase CLI** | `firebase --version` | **PASS** | Firebase CLI v14.4.0 in PATH |
| **FlutterFire CLI** | `flutterfire --version` | **PASS** | FlutterFire CLI v1.4.1 activated in Pub Cache PATH |
| **REST API** | `Invoke-RestMethod` GET | **PASS** | Internet connectivity & JSON parsing verified |
| **Firebase Auth** | `firebase_auth` Provider | **PASS** | Email/Password, Google Sign-In, Auth State streams verified |
| **Firestore** | `cloud_firestore` Provider | **PASS** | Real-time queries & CRUD operational |
| **Android Debug Build** | `flutter build apk --debug` | **PASS** | `build\app\outputs\flutter-apk\app-debug.apk` compiled |
| **Android Release Build** | `flutter build apk --release` | **PASS** | `release\app-release.apk` (52.3 MB) compiled |
| **Web Build** | `flutter build web` | **PASS** | `build\web\` compiled with zero errors |
| **Automated Tests** | `flutter test` | **PASS** | **54 / 54 unit and widget tests passing** |

---

## 📋 Remaining Manual Actions (Personal Actions for Exam)

1. **Connect Physical Android Phone via USB (if testing on real phone)**:
   - Connect your phone using a data-capable USB cable.
   - Go to phone **Settings $\rightarrow$ Developer Options $\rightarrow$ Enable USB Debugging**.
   - When prompted with **"Allow USB debugging?"**, check **"Always allow from this computer"** and tap **OK**.
   - Verify in terminal: `adb devices` (should show `<device_id> device`).

2. **Login to Firebase (if deploying or configuring fresh projects)**:
   - Run `firebase login` in PowerShell and authenticate in your browser.
