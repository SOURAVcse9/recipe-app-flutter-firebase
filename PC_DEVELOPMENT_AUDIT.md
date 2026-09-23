# PC Development Environment Audit Report

**Audit Date:** September 23, 2026  
**Target Goal:** Flutter Mobile Application Development Lab Final Exam Readiness  
**Host Machine:** Windows 11 (Version 10.0.26200.9457)

---

## 1. System Hardware & Storage

| Parameter | Specification | Status |
| :--- | :--- | :--- |
| **Operating System** | Windows 11 (25H2 / Build 26200.9457, 64-bit) | ✅ Excellent |
| **CPU** | Multi-core x64 Processor | ✅ Passed |
| **System Memory** | 16 GB RAM | ✅ Passed |
| **Disk Drive C: (System/SDKs)** | 46.35 GB Free / 202.82 GB Total | ✅ Healthy |
| **Disk Drive E: (Projects)** | 38.56 GB Free / 124.19 GB Total | ✅ Healthy |
| **Disk Drive F: (Data)** | 34.50 GB Free / 28.24 GB Total | ✅ Healthy |
| **Disk Drive G: (Storage)** | 44.03 GB Free / 205.13 GB Total | ✅ Healthy |

---

## 2. Core SDK & Toolchains

| Tool | Version | Path / Location | Status |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | `3.47.5` (channel stable) | `C:\src\flutter\bin\flutter.bat` | ✅ VERIFIED |
| **Dart SDK** | `3.13.4` (stable) | `C:\src\flutter\bin\cache\dart-sdk\bin` | ✅ VERIFIED |
| **Android SDK** | `36.0.0` (Platform 36) | `C:\Users\ASUS\AppData\Local\Android\sdk` | ✅ VERIFIED |
| **Android Licenses** | All accepted | Android SDK Manager | ✅ VERIFIED |
| **Java / JDK** | OpenJDK `21.0.5` | `C:\Program Files\Android\Android Studio\jbr` | ✅ VERIFIED |
| **Android Studio** | Latest Bundled JBR | `C:\Program Files\Android\Android Studio` | ✅ VERIFIED |
| **Android Debug Bridge (ADB)** | `1.0.41` (v36.0.0) | `C:\Users\ASUS\AppData\Local\Android\sdk\platform-tools\adb.exe` | ✅ VERIFIED |
| **Keytool** | JDK 21 Keytool | `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe` | ✅ VERIFIED |
| **Debug Keystore** | Present (`debug.keystore`) | `C:\Users\ASUS\.android\debug.keystore` | ✅ VERIFIED |
| **Git CLI** | `2.46.2.windows.1` | `C:\Program Files\Git\cmd\git.exe` | ✅ VERIFIED |
| **Node.js** | `v20.17.0` (LTS) | `C:\Program Files\nodejs\node.exe` | ✅ VERIFIED |
| **npm** | `10.8.2` | `C:\Program Files\nodejs\npm.cmd` | ✅ VERIFIED |
| **Firebase CLI** | `14.4.0` | `C:\Users\ASUS\AppData\Roaming\npm\firebase.cmd` | ✅ VERIFIED |
| **FlutterFire CLI** | `1.4.1` | `C:\Users\ASUS\AppData\Local\Pub\Cache\bin\flutterfire.bat` | ✅ VERIFIED |
| **Google Chrome** | `152.0.7977.82` | `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe` | ✅ VERIFIED |

---

## 3. Environment Variables (Permanently Configured in User PATH)

1. `C:\src\flutter\bin`
2. `C:\Users\ASUS\AppData\Local\Pub\Cache\bin`
3. `C:\Users\ASUS\AppData\Local\Android\sdk\platform-tools`
4. `C:\Program Files\Android\Android Studio\jbr\bin`
5. `C:\Users\ASUS\AppData\Roaming\npm`
6. `C:\Program Files\nodejs`
7. `C:\Program Files\Git\cmd`
8. `C:\Users\ASUS\AppData\Local\Programs\Microsoft VS Code\bin`
9. `JAVA_HOME` = `C:\Program Files\Android\Android Studio\jbr`
10. `ANDROID_HOME` = `C:\Users\ASUS\AppData\Local\Android\sdk`

---

## 4. VS Code Extensions Audit

- `dart-code.flutter` (Flutter support, hot reload/restart)
- `dart-code.dart-code` (Dart language server & analyzer)
- `rangav.vscode-thunder-client` (Built-in GUI REST API Client)
- `humao.rest-client` (File-based `.http` REST API testing)
- `jeroen-meijer.pubspec-assist` (One-click pubspec package manager)
- `toba.vsfire` (Firebase & Firestore explorer)
- `redhat.vscode-yaml` (YAML formatter & schema validation)
- `mhutchie.git-graph` (Git commit & branching graph)
- `usernamehw.errorlens` (Inline error & warning diagnostics)

---

## 5. Summary Audit Conclusion

The development environment has been audited and tuned. All SDK binaries, compilers, build systems, cloud command-line interfaces, and editor toolings are accessible from any terminal and fully ready for exam execution.
