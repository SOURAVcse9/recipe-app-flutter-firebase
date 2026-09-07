# 🍳 Flutter + Firebase Recipe App

<p align="center">
  <img src="assets/icons/app_icon.png" alt="Recipe App Logo" width="120" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>A Production-Grade, Cross-Platform Recipe Discovery & Cooking Companion Application</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Firebase-Spark_Plan-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platforms-Android%20|%20Web%20|%20Windows-4CAF50?style=for-the-badge" alt="Platforms"/>
  <img src="https://img.shields.io/badge/Tests-36%20Passing-brightgreen?style=for-the-badge" alt="Tests"/>
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"/>
</p>

---

## 📥 Download Release APK

The latest production release APK is built and ready for Android devices:

| Version | Target | File | Size | Link |
| :--- | :--- | :--- | :--- | :--- |
| **v1.0.0 (Release)** | Android (ARM64 / ARMv7 / x86_64) | `app-release.apk` | ~52 MB | [⬇️ Download Direct APK](release/app-release.apk) |

> 💡 **Installation Note**: Enable **"Install from unknown sources"** on your Android device settings if prompted when opening the downloaded `.apk` file.

---

## ✨ Key Features

### 🔐 1. Production-Grade Firebase Authentication
* **Email/Password**: Signup, login, real-time validation, and password strength indicators.
* **Email Verification**: Built-in verification flow with a 60-second resend cooldown timer and reactive state refresh.
* **Enumeration-Safe Password Recovery**: Protects against account enumeration attacks.
* **Cross-Platform Google Sign-In**:
  * **Web (Chrome / Edge)**: Employs native Firebase Web popup authentication (`signInWithPopup(GoogleAuthProvider())`) that works seamlessly without client-side Client ID origin mismatches on `localhost`.
  * **Android**: Uses native Google Sign-In SDK with Firebase credential authentication.
* **Clean Session Isolation**: Automatic FCM token synchronization on login and complete token revocation/cache clearing on logout or account switching.

---

### 🍲 2. Dynamic 25-Recipe Catalog
* **25 Recipes** across **5 Categories** (Breakfast, Dessert, Dinner, Lunch, Vegetables).
* **Multi-Parameter Search & Filtering**: Real-time search across recipe names, ingredients, and categories.
* **Curated Discovery Feeds**: "Popular Recipes" (ordered by dynamic view counts) and "Top Rated" feeds.
* **Fail-Safe Image Loading**: All network images render through `SafeNetworkImage` featuring loading animations, placeholder fallbacks (`Iconsax.reserve`), and error boundary recovery.

---

### 📖 3. Interactive Detail View & Cooking Companion
* **Step-by-Step Cooking Instructions**: Numbered instruction cards formatted to the dark/orange theme. Sections hide automatically if instructions are unavailable.
* **Dynamic Serving Scaler**: Multiplies integer, decimal, and fractional ingredient amounts dynamically while preserving units.
* **Built-in Cooking Timer**: Countdown timer configured directly to each recipe's cooking duration.
* **Reviews & Ratings System**: User review submissions, real-time aggregate score recalculation, and duplicate review prevention.
* **Integrated Shopping List**: Add ingredients directly to a personalized shopping list with one-tap completion checkboxes.
* **Recently Viewed History**: Tracks viewed recipes with chronological timestamp ordering.

---

### 🔔 4. Firebase Cloud Messaging (FCM)
* **Android & Web Push Notifications**: Service worker integration (`web/firebase-messaging-sw.js`) for background push alerts.
* **User-Managed Notification Preferences**: Persisted toggles for Recommendations, New Recipes, and Cooking Reminders.
* **In-App Foreground Alerts**: SnackBars with deep-linking directly into recipe detail screens.
* **Permission Status Indicators**: Dynamic UI cards showing permission status (Granted, Denied, Prompt, or Windows Desktop fallback).

---

### 🎨 5. Theme & App Customizations
* **Theme Modes**: Supports Dark, Light, and System themes.
* **Display Preferences**: Custom toggles for calorie counters, cooking time badges, default serving quantities, and search case-sensitivity.

---

## 🏛️ Architecture & Project Structure

The project uses a clean **Provider + Repository Architecture**:

```
lib/
├── main.dart                       # App entry point, Firebase init & AuthWrapper
├── firebase_options.dart           # Cross-platform Firebase config
├── models/                         # Immutable models & Firestore serializers
│   ├── app_preferences.dart        # User settings & layout preferences
│   ├── food_category.dart          # Recipe category model
│   ├── recipe.dart                 # Recipe model with safe array coercion & instructions
│   ├── review.dart                 # Review & rating model
│   ├── shopping_list_item.dart     # Shopping list model with toggleable status
│   └── recently_viewed.dart        # Recently viewed history model
├── providers/                      # State management layer (ChangeNotifiers)
│   ├── auth_provider.dart          # Auth lifecycle, error mapping & token hooks
│   ├── preferences_provider.dart   # Real-time user preferences
│   ├── recipe_provider.dart        # Recipe streaming, search, filters & servings
│   ├── review_provider.dart        # Review submissions & stream listeners
│   ├── shopping_list_provider.dart # Shopping list item management
│   └── recently_viewed_provider.dart # Recipe viewing history
├── repositories/                   # Data access layer (Firestore & Auth abstractions)
│   ├── auth_repository.dart        # Firebase Auth & Google Sign-In logic
│   ├── preferences_repository.dart # Firestore user preferences CRUD
│   ├── recipe_repository.dart      # Recipe & category stream queries
│   └── review_repository.dart      # Reviews index & aggregate calculations
├── screens/                        # UI Screens
│   ├── main_navigation.dart        # Root bottom navigation shell
│   ├── home_screen.dart            # Home discovery feed & category tabs
│   ├── recipe_detail_screen.dart   # Interactive detail view, timer & instructions
│   ├── favorites_screen.dart       # User-favorited recipes list
│   ├── profile_screen.dart         # User profile, account info & settings navigation
│   ├── login_screen.dart           # Email & Google login
│   ├── signup_screen.dart          # Email signup with password validation
│   ├── verification_screen.dart    # Email verification & resend cooldown
│   ├── forgot_password_screen.dart # Password recovery
│   ├── notifications_screen.dart   # Push notifications & preference toggles
│   ├── app_preferences_screen.dart # Theme & display settings
│   └── shopping_list_screen.dart   # User shopping list
├── services/
│   └── notification_service.dart   # Centralized FCM setup, tokens, permissions & routing
├── utils/
│   ├── app_theme.dart              # Custom color palette, typography & ThemeData
│   └── ingredient_scaler.dart      # Fraction & unit parsing mathematical scaler
└── widgets/                        # Modular reusable UI widgets
    ├── recipe_card.dart            # Discovery grid recipe tile
    ├── category_chip.dart          # Filter chip widget
    ├── safe_network_image.dart     # Network image loader with error/progress fallbacks
    ├── ingredient_tile.dart        # Scaled ingredient item row
    ├── quantity_selector.dart      # +/- serving controller
    ├── timer_widget.dart           # Interactive cooking timer
    ├── rating_widget.dart          # Star rating & review counter
    └── favorite_button.dart        # Animated favorite heart toggle
```

---

## 🗄️ Firestore Database Schema

```
recipes/ {recipeId}                 # Public read-only recipe catalog
categories/ {categoryId}            # Public read-only food categories
users/ {uid}                        # Private user profile document
  ├── favorites/ {recipeId}         # User favorited recipes
  ├── preferences/ settings         # User theme & notification settings
  ├── shoppingList/ {itemId}        # User shopping list items
  ├── recentlyViewed/ {recipeId}    # Recipe view history
  ├── reviews/ {recipeId}           # User-submitted reviews
  └── notification_tokens/ {tokenId}# Multi-device FCM registration tokens
```

---

## 🚀 Setup & Local Installation

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.0 or higher)
* [Node.js](https://nodejs.org/) (for running database seed scripts)
* [Firebase CLI](https://firebase.google.com/docs/cli) & [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

### 2. Clone the Repository
```bash
git clone https://github.com/<YOUR-USERNAME>/recipe-app-flutter-firebase.git
cd recipe-app-flutter-firebase
```

### 3. Connect Your Firebase Project
1. Create a project in the [Firebase Console](https://console.firebase.google.com/) (Compatible with the free **Spark Plan**).
2. Enable **Authentication** (Email/Password & Google) and **Cloud Firestore**.
3. Configure your Flutter app with FlutterFire:
   ```bash
   flutterfire configure
   ```
4. Deploy Firestore security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 4. Seed the 25 Recipes Dataset
1. Download a service account private key from **Firebase Console -> Project Settings -> Service Accounts -> Generate new private key**.
2. Save it as `serviceAccountKey.json` in the project root or `sample_data/` folder.
3. Run the automated seed script:
   ```bash
   cd sample_data
   npm install
   node seed.js
   ```

---

## 💻 Run the Application

```bash
# Get dependencies
flutter pub get

# Run on Web (Chrome)
flutter run -d chrome

# Run on Physical Android USB Device
flutter run -d <device-id>

# Run on Windows Desktop
flutter run -d windows
```

---

## 🧪 Automated Testing & Verification

The project includes a test suite with 36 unit, widget, and programmatic schema validation tests:

```bash
# Run static analysis
flutter analyze

# Execute all automated test suites
flutter test

# Build production artifacts
flutter build web --no-tree-shake-icons
flutter build apk --release --no-tree-shake-icons
```

---

## 🔒 Security & Privacy Notice

* **No Hardcoded Credentials**: API secrets, private keystores, and service account JSONs (`serviceAccountKey.json`) are excluded via `.gitignore`.
* **Database Isolation**: Granular Firestore rules enforce strict user-level data segregation under `users/{uid}`.
* **Spark Plan Compatible**: Operates entirely within the free Firebase Spark tier without requiring paid Cloud Functions or external APIs.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
