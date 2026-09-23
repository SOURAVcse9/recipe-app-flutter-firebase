# Flutter Lab Exam Troubleshooting Guide

Top 20 high-frequency issues encountered during Flutter, Android, Firebase, and REST API development exams — with exact causes, fixes, and terminal commands.

---

### 1. `flutter` is not recognized as an internal or external command
* **Cause**: Flutter SDK `bin` folder is missing from the Windows PATH environment variable.
* **Fix**: Add `C:\src\flutter\bin` to PATH.
* **Command (PowerShell)**:
  ```powershell
  $env:Path = "C:\src\flutter\bin;" + $env:Path
  ```

---

### 2. `dart` is not recognized
* **Cause**: Dart SDK (bundled inside Flutter at `cache\dart-sdk\bin`) or Flutter bin is not in PATH.
* **Fix**: Ensure `C:\src\flutter\bin` is in PATH.
* **Command**:
  ```powershell
  dart --version
  ```

---

### 3. `flutterfire` is not recognized
* **Cause**: Global Pub executables directory is missing from PATH.
* **Fix**: Add `C:\Users\<User>\AppData\Local\Pub\Cache\bin` to PATH and reactivate.
* **Command**:
  ```powershell
  dart pub global activate flutterfire_cli
  $env:Path = "$env:LOCALAPPDATA\Pub\Cache\bin;" + $env:Path
  ```

---

### 4. `firebase` is not recognized
* **Cause**: Global npm bin directory (`AppData\Roaming\npm`) is missing from PATH.
* **Fix**: Add npm global directory to PATH or reinstall via npm.
* **Command**:
  ```powershell
  npm install -g firebase-tools
  ```

---

### 5. `keytool` is not recognized
* **Cause**: JDK bin folder is not in PATH.
* **Fix**: Use the bundled Android Studio JDK (`jbr\bin`).
* **Command**:
  ```powershell
  $env:Path = "C:\Program Files\Android\Android Studio\jbr\bin;" + $env:Path
  keytool -version
  ```

---

### 6. `adb` is not recognized
* **Cause**: Android SDK `platform-tools` folder is missing from PATH.
* **Fix**: Add `AppData\Local\Android\sdk\platform-tools` to PATH.
* **Command**:
  ```powershell
  $env:Path = "$env:LOCALAPPDATA\Android\sdk\platform-tools;" + $env:Path
  adb devices
  ```

---

### 7. Device status shows `unauthorized` in `adb devices`
* **Cause**: The Android device has not trusted the computer's RSA key fingerprint.
* **Fix**: Unlock your Android phone, look for the popup **"Allow USB debugging?"**, check **"Always allow from this computer"**, and tap **Allow**.
* **Command**:
  ```powershell
  adb kill-server
  adb start-server
  adb devices
  ```

---

### 8. Device status shows `offline` or fails to connect
* **Cause**: Loose USB cable, bad charging-only cable, or ADB server communication glitch.
* **Fix**: Unplug and reconnect USB cable, set USB connection mode to **File Transfer / MTP** on phone, and restart ADB.
* **Command**:
  ```powershell
  adb reconnect
  adb devices
  ```

---

### 9. Gradle build failed (`assembleDebug` or `assembleRelease` error)
* **Cause**: Corrupted Gradle cache or incompatible Gradle wrapper version.
* **Fix**: Clean the Flutter project and delete Gradle cache.
* **Command**:
  ```powershell
  flutter clean
  flutter pub get
  cd android ; .\gradlew clean ; cd ..
  flutter build apk --debug
  ```

---

### 10. Kotlin compilation error (`Kotlin Gradle Plugin` mismatch)
* **Cause**: Kotlin version in `android/settings.gradle` / `android/build.gradle` is incompatible with the installed Flutter version.
* **Fix**: Use Flutter's standard Kotlin plugin integration or update Kotlin version to `1.9.24` / `2.0.0`.
* **Command**:
  ```powershell
  flutter clean
  flutter pub get
  ```

---

### 11. Java / JDK mismatch (`Unsupported class file major version`)
* **Cause**: Android Gradle Plugin requires Java 17 or Java 21, but an older Java 8/11 was active.
* **Fix**: Set `JAVA_HOME` to Android Studio's bundled OpenJDK (`jbr`).
* **Command**:
  ```powershell
  $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
  flutter doctor -v
  ```

---

### 12. Android license error (`Android license status unknown`)
* **Cause**: Android SDK platform components updated without accepting licenses.
* **Fix**: Run the interactive license acceptor and type `y` to all prompts.
* **Command**:
  ```powershell
  flutter doctor --android-licenses
  ```

---

### 13. Firebase initialization error (`No Firebase App '[DEFAULT]' has been created`)
* **Cause**: `WidgetsFlutterBinding.ensureInitialized()` or `Firebase.initializeApp()` was not awaited before running the app.
* **Fix**: Update `lib/main.dart` with:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  }
  ```

---

### 14. Google Sign-In error (`ApiException: 10` or `DEVELOPER_ERROR`)
* **Cause**: SHA-1 fingerprint of the debug keystore is missing from the Firebase Console Project Settings.
* **Fix**: Copy SHA-1 fingerprint from `keytool` and paste it into Firebase Console $\rightarrow$ Project Settings $\rightarrow$ Android Apps.
* **Command to get SHA-1**:
  ```powershell
  keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
  ```

---

### 15. REST API Timeout / Connection Refused
* **Cause**: Calling `http://localhost:<port>` on an Android Emulator / Physical Device (where localhost refers to the phone itself, not your PC).
* **Fix**:
  - Android Emulator: Use `http://10.0.2.2:<port>`
  - Physical Phone: Use your computer's local Wi-Fi IP (e.g., `http://192.168.1.X:<port>`) or a live HTTPS server.
  - Test connectivity in PowerShell:
  ```powershell
  Invoke-WebRequest -Uri "https://dummyjson.com/products/1" -Method Get
  ```

---

### 16. JSON parsing error (`type 'String' is not a subtype of type 'num'`)
* **Cause**: API returned a number as a string (or vice-versa), or a null value in a non-nullable model field.
* **Fix**: Use defensive parsing in Dart models:
  ```dart
  price: (json['price'] != null) ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
  ```

---

### 17. UI `RenderFlex overflowed by X pixels`
* **Cause**: A `Column` or `Row` contains children that exceed the available screen height/width.
* **Fix**: Wrap the `Column` inside a `SingleChildScrollView` or wrap expanding children in `Expanded` / `Flexible`.
  ```dart
  SingleChildScrollView(
    child: Column(children: [...]),
  )
  ```

---

### 18. Package not found in `pubspec.yaml`
* **Cause**: Typo in package name or incorrect YAML indentation (tabs instead of spaces).
* **Fix**: Use `flutter pub add <package>` instead of manual editing.
* **Command**:
  ```powershell
  flutter pub add http
  ```

---

### 19. `flutter pub get` failure (`Git error` / `Connection reset`)
* **Cause**: Temporary network drop or locked `.dart_tool` directory.
* **Fix**: Delete `.dart_tool` and lockfile, then re-run `flutter pub get`.
* **Command**:
  ```powershell
  Remove-Item -Recurse -Force .dart_tool
  flutter pub get
  ```

---

### 20. Chrome Flutter run failure (`Failed to bind to port`)
* **Cause**: A zombie Chrome process or debugging port conflict.
* **Fix**: Close existing Chrome debug instances and launch with clean state.
* **Command**:
  ```powershell
  flutter run -d chrome --web-port=8080
  ```
