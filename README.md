# 🍳 Flutter + Firebase Recipe App

<p align="center">
  <img src="assets/icons/app_icon.png" alt="Recipe App Logo" width="130"/>
</p>

<p align="center">
  <b>A Production-Grade, Cross-Platform Recipe Discovery & Cooking Companion Application</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/></a>
  <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-Spark_Free_Tier-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/></a>
  <img src="https://img.shields.io/badge/Platforms-Android%20|%20Web%20|%20Windows-4CAF50?style=for-the-badge" alt="Platforms"/>
  <img src="https://img.shields.io/badge/Tests-44%20Passing-brightgreen?style=for-the-badge" alt="Tests"/>
  <a href="https://github.com/SOURAVcse9/recipe-app-flutter-firebase/releases"><img src="https://img.shields.io/badge/Release-v1.0.0-orange?style=for-the-badge&logo=android&logoColor=white" alt="Release"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License"/></a>
</p>

<p align="center">
  <img src="https://komarev.com/ghpvc/?username=SOURAVcse9&repo=recipe-app-flutter-firebase&color=007ec6&style=for-the-badge&label=VISITORS" alt="Visitors"/>
  <a href="https://github.com/SOURAVcse9/recipe-app-flutter-firebase/releases"><img src="https://img.shields.io/github/downloads/SOURAVcse9/recipe-app-flutter-firebase/total?style=for-the-badge&logo=android&logoColor=white&color=brightgreen&label=APK%20DOWNLOADS" alt="APK Downloads"/></a>
</p>

---

## 📥 Download Production Release APK

The compiled production APK is ready for direct installation on Android devices:

<p align="center">
  <a href="https://github.com/SOURAVcse9/recipe-app-flutter-firebase/raw/main/release/app-release.apk">
    <img src="https://img.shields.io/badge/⬇️_Direct_Download-app--release.apk-2ea44f?style=for-the-badge&logo=android&logoColor=white" alt="Direct Download APK"/>
  </a>
</p>

| Release | Target | File | Size | Direct Download |
| :--- | :--- | :--- | :--- | :--- |
| **v1.0.0 (Production Release)** | Android (ARM64 / ARMv7 / x86_64) | `app-release.apk` | ~52.5 MB | [⬇️ **Direct Download APK**](https://github.com/SOURAVcse9/recipe-app-flutter-firebase/raw/main/release/app-release.apk) |

> 📦 **GitHub Releases**: You can also download the asset directly from the [GitHub Releases Page](https://github.com/SOURAVcse9/recipe-app-flutter-firebase/releases/tag/v1.0.0).  
> 💡 **Android Installation Note**: If prompted, allow **"Install unknown apps"** in your Android device settings.

---

## ✨ Key Features & Capabilities

### 🛡️ 1. Role-Based Production Architecture (Admin + Audience)
* **Custom Claims-Gated Admin Access**: Admin roles are managed strictly via Firebase Auth Custom Claims (`admin: true`) via backend scripts (`sample_data/set_admin.js`), completely eliminating client-side tampering and public admin registration.
* **Interactive Admin Dashboard (`/admin`)**:
  * **Analytics Overview**: Real-time KPI summary cards (Total Recipes, Published, Drafts, Total Categories, Active Categories).
  * **Quick Actions**: Direct navigation to create recipes, manage categories, and audit content.
* **Comprehensive Admin Recipe Management**:
  * **Dynamic Ingredient & Step Builders**: Add/remove/reorder ingredients with fractional amounts and step-by-step instructions.
  * **Firebase Storage Image Upload**: Validated image uploader with format restrictions (JPG, PNG, WEBP) and 5MB size limits.
  * **Draft & Publish Controls**: Toggle publication state instantly or save drafts without exposing them to audience feeds.
  * **Safety Checks**: Deletion confirmations and search/filtering across drafts & published recipes.
* **Category Management**:
  * Category CRUD with duplicate name prevention and active/inactive status toggles.
  * Dependency-aware deletion prevents removing categories that have linked recipes.
* **Audience Isolation**:
  * Regular users only read published recipes (`isPublished == true`) and active categories (`isActive == true`).
  * Private user data (favorites, preferences, reviews, history) is strictly isolated under `users/{uid}/`.

---

### 🔐 2. Production-Grade Firebase Authentication
* **Email & Password Authentication**: Complete signup, sign-in, and real-time form validation with password strength scoring.
* **Email Verification**: Verification banner with a 60-second rate-limited resend cooldown timer and reactive state refresh.
* **Enumeration-Safe Password Recovery**: Sanitized password reset flow that prevents account enumeration attacks.
* **Cross-Platform Google Sign-In**:
  * **Web (Chrome / Edge)**: Uses native Firebase Web popup authentication (`signInWithPopup(GoogleAuthProvider())`) which avoids client-side Client ID origin mismatches and port issues on `localhost`.
  * **Android**: Uses native Google Sign-In SDK with Firebase credential authentication.
* **Session Lifecycle & Security**: Automatic FCM token synchronization on login, and complete token revocation and cache cleanup on logout or account switching.

---

### 🍲 3. Dynamic Recipe Catalog & Search
* **Active Category & Recipe Discovery**: Audience-filtered real-time Firestore streams.
* **Multi-Parameter Search & Filtering**: Fast, case-insensitive search by recipe name or ingredient, combined with interactive category filter chips.
* **Curated Feeds**: Dynamic "Popular Recipes" (ordered by real-time view counts) and "Top Rated" feeds.
* **Fail-Safe Image Loading**: All images render through `SafeNetworkImage` featuring loading animations, placeholder fallbacks (`Iconsax.reserve`), and error boundary recovery.

---

### 📖 4. Interactive Detail View & Cooking Companion
* **Step-by-Step Cooking Instructions**: Numbered badge instruction cards formatted to the dark/orange theme. Automatically hides if instructions are unavailable.
* **Dynamic Serving Scaler**: Multiplies integer, decimal, and fractional ingredient amounts dynamically while preserving units.
* **Integrated Cooking Timer**: Built-in interactive countdown timer tailored to each recipe's cooking duration.
* **Reviews & Ratings System**: User review submissions, aggregate rating calculation, and duplicate review prevention.
* **Shopping List Integration**: Add ingredients directly to a personalized shopping list with one-tap completion checkboxes.
* **Recently Viewed History**: Tracks viewed recipes with chronological timestamp ordering.

---

### 🔔 5. Push Notifications & Event Triggers
* **Cloud Functions (`functions/`)**: Event-driven Firebase Functions listening to Firestore `onCreate` events to dispatch FCM alerts when new recipes or categories are published.
* **Invalid Token Self-Cleaning**: Automatically prunes stale/invalid FCM device tokens on failure (`messaging/invalid-registration-token`, `messaging/registration-token-not-registered`).
* **User-Managed Notification Preferences**: Real-time Firestore-persisted toggles for recipe recommendations, new recipe alerts, and cooking reminders.

---

### 🎨 6. Theme & App Customizations
* **Theme Modes**: Supports Dark, Light, and System themes.
* **Display Preferences**: Custom toggles for calorie counters, cooking time badges, default serving quantities, and search case-sensitivity.

---

## 🏛️ Architecture & Project Structure

```
lib/
├── main.dart                       # App entry point, Firebase init & role-based AuthWrapper
├── firebase_options.dart           # Cross-platform Firebase config
├── models/                         # Immutable models & Firestore serializers
│   ├── app_preferences.dart        # User settings & layout preferences
│   ├── food_category.dart          # Category model (isActive, searchName)
│   ├── recipe.dart                 # Recipe model (IngredientItem, isPublished, legacy array compatibility)
│   ├── review.dart                 # Review & rating model
│   ├── shopping_list_item.dart     # Shopping list model with toggleable status
│   └── recently_viewed.dart        # Recently viewed history model
├── providers/                      # State management layer (ChangeNotifiers)
│   ├── auth_provider.dart          # Auth lifecycle, custom claims admin verification
│   ├── preferences_provider.dart   # Real-time user preferences
│   ├── recipe_provider.dart        # Role-aware recipe streaming, search, filters & CRUD
│   ├── review_provider.dart        # Review submissions & stream listeners
│   ├── shopping_list_provider.dart # Shopping list item management
│   └── recently_viewed_provider.dart # Recipe viewing history
├── repositories/                   # Data access layer (Firestore & Auth abstractions)
│   ├── auth_repository.dart        # Firebase Auth, Google Sign-In & custom claims reader
│   ├── preferences_repository.dart # Firestore user preferences CRUD
│   ├── recipe_repository.dart      # Role-isolated Recipe & Category stream queries and CRUD
│   └── review_repository.dart      # Reviews index & aggregate calculations
├── screens/                        # UI Screens
│   ├── main_navigation.dart        # Root bottom navigation shell for Audience
│   ├── home_screen.dart            # Home discovery feed & category tabs
│   ├── recipe_detail_screen.dart   # Interactive detail view, timer & instructions
│   ├── favorites_screen.dart       # User-favorited recipes list
│   ├── profile_screen.dart         # User profile, account info & Admin Dashboard shortcut
│   ├── login_screen.dart           # Email & Google login
│   ├── signup_screen.dart          # Email signup with password validation
│   ├── verification_screen.dart    # Email verification & resend cooldown
│   ├── forgot_password_screen.dart # Password recovery
│   ├── notifications_screen.dart   # Push notifications & preference toggles
│   ├── app_preferences_screen.dart # Theme & display settings
│   ├── shopping_list_screen.dart   # User shopping list
│   └── admin/                      # Role-Gated Admin Portal Screens
│       ├── admin_dashboard_screen.dart   # Analytics overview & quick navigation
│       ├── admin_recipes_screen.dart     # Recipe management, search & filters
│       ├── add_recipe_screen.dart        # Recipe creator with dynamic builders & storage upload
│       ├── edit_recipe_screen.dart       # Recipe editor
│       ├── admin_categories_screen.dart  # Category list & status toggles
│       ├── add_category_screen.dart      # Category creator with duplicate check
│       └── edit_category_screen.dart     # Category editor
├── services/
│   ├── notification_service.dart   # Centralized FCM setup, tokens, permissions & routing
│   └── storage_service.dart        # Firebase Storage image uploads (5MB limit, format checks)
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

functions/                          # Cloud Functions for FCM event triggers
├── index.js                        # OnCreate triggers for recipes & categories
└── package.json                    # Firebase Admin & Functions dependencies

sample_data/
├── seed.js                         # Initial 25-recipe database seed script
└── set_admin.js                    # Admin Custom Claims CLI assignment script
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
git clone https://github.com/SOURAVcse9/recipe-app-flutter-firebase.git
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

The project includes a comprehensive test suite with 36 unit, widget, and programmatic schema validation tests:

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

* **No Hardcoded Credentials**: API secrets, private keystores, and service account JSONs (`serviceAccountKey.json`) are strictly excluded via `.gitignore`.
* **Database Isolation**: Granular Firestore rules enforce strict user-level data segregation under `users/{uid}`.
* **Spark Plan Compatible**: Operates entirely within the free Firebase Spark tier without requiring paid Cloud Functions or external APIs.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
