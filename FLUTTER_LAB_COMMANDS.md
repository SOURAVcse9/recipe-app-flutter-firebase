# Flutter Mobile Application Development Lab Exam Cheat Sheet

A comprehensive, field-tested reference guide for all essential commands needed during your Flutter & Firebase Lab Exam.

---

## 1. Environment & Device Verification

### `flutter doctor -v`
* **What it does**: Performs a deep diagnostic check of Flutter SDK, Android toolchain, Java JDK, Android Studio, VS Code, and connected devices.
* **When to use it**: At the very beginning of the exam or when any compilation/device detection issue occurs.
* **Common Error**: `Android license status unknown` $\rightarrow$ **Fix**: Run `flutter doctor --android-licenses` and press `y` to accept all licenses.

### `flutter devices`
* **What it does**: Lists all active devices and emulators (USB-connected physical phone, Chrome Web, Windows Desktop, Android Emulator).
* **When to use it**: To find your target device ID before running your application.
* **Common Error**: `No devices found` $\rightarrow$ **Fix**: Check USB cable connection, ensure **USB Debugging** is turned ON in developer options, and unlock the phone screen.

### `adb devices`
* **What it does**: Direct Android Debug Bridge query checking physical and virtual Android device connections.
* **When to use it**: To verify USB cable connection and authorization status.
* **Common Error**: `unauthorized` $\rightarrow$ **Fix**: Unlock your phone and tap **"Always allow from this computer"** on the popup prompt.

---

## 2. Project Creation & Dependency Management

### `flutter create <project_name>`
* **What it does**: Generates a standard, complete Flutter project structure with Android, iOS, and Web support.
* **When to use it**: When starting a new exam question or fresh application.
* **Common Error**: `"<project_name>" is not a valid Dart package name` $\rightarrow$ **Fix**: Use lowercase letters and underscores only (e.g., `flutter create recipe_app`, never `Recipe-App`).

### `flutter pub add <package_name>`
* **What it does**: Adds a dependency to `pubspec.yaml` and downloads it automatically without needing manual YAML editing.
* **When to use it**: When adding libraries like `provider`, `http`, `firebase_core`, `cloud_firestore`, `firebase_auth`, `shared_preferences`.
  - *Example*: `flutter pub add provider http`
* **Common Error**: `Package not found` $\rightarrow$ **Fix**: Check spelling against [pub.dev](https://pub.dev).

### `flutter pub get`
* **What it does**: Downloads and resolves all dependencies listed in `pubspec.yaml`.
* **When to use it**: After cloning a repo, modifying `pubspec.yaml`, or switching branches.
* **Common Error**: `A dependency requires SDK version...` $\rightarrow$ **Fix**: Check your `environment: sdk:` constraint in `pubspec.yaml`.

---

## 3. Execution, Testing & Quality Checks

### `flutter run`
* **What it does**: Builds, installs, launches the app on your selected device, and starts the interactive hot reload session.
* **When to use it**: For developing and testing your UI and business logic interactively.
* **Key Shortcuts during `flutter run`**:
  - Press `r` $\rightarrow$ **Hot Reload** (instant UI update preserving state)
  - Press `R` $\rightarrow$ **Hot Restart** (re-runs `main()` and resets state)
  - Press `q` $\rightarrow$ **Quit** running session

### `flutter run -d <device_id>`
* **What it does**: Targets a specific device directly (e.g., `flutter run -d chrome` or `flutter run -d <phone-serial>`).
* **When to use it**: When multiple devices (Chrome, Android phone, Desktop) are connected.

### `flutter clean`
* **What it does**: Deletes the `build/` directory and ephemeral cache files.
* **When to use it**: When encountering mysterious Gradle build errors, stale asset caches, or build failures.
* **Best Practice**: Always follow with `flutter pub get`.

### `flutter analyze`
* **What it does**: Runs the Dart static analyzer across all code in `lib/` and `test/` to detect syntax errors, type mismatches, and dead code.
* **When to use it**: Before submitting code or taking final screenshots.
* **Target**: Aim for `No issues found!`.

### `flutter test`
* **What it does**: Executes all unit and widget tests located in the `test/` directory.
* **When to use it**: To verify logic, JSON serialization, and data calculations.

---

## 4. Production Binary & Web Builds

### `flutter build apk --debug`
* **What it does**: Compiles a debug Android APK package (`build/app/outputs/flutter-apk/app-debug.apk`).
* **When to use it**: For rapid testing on Android without needing signing keys.

### `flutter build apk --release`
* **What it does**: Compiles an optimized, tree-shaken, production release APK (`build/app/outputs/flutter-apk/app-release.apk`).
* **When to use it**: When the exam asks for a submission APK or final release file.

### `flutter build web --no-tree-shake-icons`
* **What it does**: Compiles the entire Flutter application into HTML, CSS, and WebAssembly / JavaScript in `build/web/`.
* **When to use it**: When deploying to Firebase Hosting or GitHub Pages.

---

## 5. Firebase & FlutterFire Commands

### `firebase login`
* **What it does**: Authenticates the Firebase CLI with your Google Account via the browser.
* **When to use it**: Once before running Firebase deployment or FlutterFire configuration.

### `firebase projects:list`
* **What it does**: Lists all Firebase projects linked to your logged-in Google account.
* **When to use it**: To confirm your Firebase Project ID (e.g., `recipe-app-81189`).

### `flutterfire configure`
* **What it does**: Automatically registers Android/Web/iOS platforms with your Firebase project and generates `lib/firebase_options.dart`.
* **When to use it**: When integrating Firebase into a new Flutter project.
* **Common Error**: `flutterfire: command not found` $\rightarrow$ **Fix**: Run `dart pub global activate flutterfire_cli` and ensure pub cache bin is in PATH.

### `firebase deploy --only firestore:rules`
* **What it does**: Pushes local `firestore.rules` directly to the live Firebase Cloud Firestore database.
* **When to use it**: When updating database security rules without opening the browser.

---

## 6. Git Version Control

### `git init`
* **What it does**: Initializes a new Git repository in the current folder.
* **When to use it**: At the beginning of a fresh project.

### `git status`
* **What it does**: Shows modified, staged, and untracked files.
* **When to use it**: Before staging or committing to ensure you aren't committing sensitive secret files.

### `git add .`
* **What it does**: Stages all modified and new files matching `.gitignore`.

### `git commit -m "feat: implement user authentication and home ui"`
* **What it does**: Records staged changes to the repository history with a meaningful commit message.

### `git push origin main`
* **What it does**: Uploads local commits to the remote GitHub repository.

---

## 7. Useful REST API & Node Utilities

### `Invoke-RestMethod -Uri "<API_URL>" -Method Get` (PowerShell)
* **What it does**: Tests external REST API endpoints directly from PowerShell before writing Flutter code.
  - *Example*: `Invoke-RestMethod -Uri "https://dummyjson.com/recipes" -Method Get`

### `npm install` & `npm run`
* **What it does**: Installs Node dependencies and executes custom scripts (e.g., seed scripts in `sample_data/`).
