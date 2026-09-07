# 🍳 Flutter + Firebase Recipe App

A production-ready, cross-platform recipe discovery and cooking companion application built with **Flutter** and **Firebase**. The app is **100% dynamic and Firebase-driven**—all recipes, categories, user profiles, reviews, favorites, shopping lists, preferences, and notifications are synchronized in real-time with Cloud Firestore and Firebase Authentication.

---

## 📱 Features

### 🔐 1. Production-Grade Authentication
* **Email & Password**: Full signup, login, and validation with password strength requirements.
* **Email Verification**: Built-in verification flow with 60-second resend cooldown timer and reactive state refresh.
* **Enumeration-Safe Password Reset**: Secure password recovery that protects against account enumeration attacks.
* **Google Sign-In**:
  * **Web (Chrome / Edge)**: Uses native Firebase Web popup authentication (`signInWithPopup(GoogleAuthProvider())`) avoiding client-side ID mismatches and port issues on `localhost`.
  * **Android**: Uses native Google Sign-In SDK with Firebase credential authentication.
* **Session Persistence & Isolation**: Reactive auth state listener with automatic token registration and cleanup upon logout or account switching.

### 🍲 2. Dynamic Recipe Discovery & Exploration
* **25 Production Recipes** across 5 distinct categories:
  * 🥞 **Breakfast** (5 recipes)
  * 🍰 **Dessert** (5 recipes)
  * 🍛 **Dinner** (5 recipes)
  * 🍱 **Lunch** (5 recipes)
  * 🥗 **Vegetables** (5 recipes)
* **Real-Time Search & Filtering**: Multi-term search by recipe name or ingredient combined with category chip filtering.
* **Curated Feeds**: Dynamic "Popular Recipes" (by view count) and "Top Rated" sections.
* **Fail-Safe Image Loading**: All images render through `SafeNetworkImage` with animated progress loading, fallback placeholder icons (`Iconsax.reserve`), and error boundary recovery.

### 📖 3. Interactive Recipe Details & Cooking Companion
* **Step-by-Step Cooking Instructions**: Clean, numbered instruction cards with typography matching the dark/orange theme. Sections hide automatically if instructions are unavailable.
* **Dynamic Ingredient Quantity Scaler**: Interactive serving multiplier (`+` / `-`) that scales integer, decimal, and fraction ingredient amounts dynamically while preserving units.
* **Integrated Cooking Timer**: Built-in interactive countdown timer tailored to the specific recipe cooking time.
* **Reviews & Ratings**: User review submission, aggregate rating calculation, and duplicate review prevention.
* **Shopping List Integration**: Add missing ingredients directly to your personal shopping list with one-tap completion toggles.
* **Recently Viewed Tracking**: Automatically tracks recently viewed recipes with timestamp ordering.

### 🔔 4. Firebase Cloud Messaging (FCM) Notifications
* **Cross-Platform Support**: Native push notification integration for Android and Web.
* **Service Worker Integration**: Compat-mode `web/firebase-messaging-sw.js` for background web pushes.
* **Notification Preferences**: Real-time Firestore-persisted toggles for:
  * Recipe recommendations
  * New recipe alerts
  * Cooking reminders
* **In-App Foreground Alerts**: Custom SnackBar banners for foreground notifications with direct deep-linking to recipe detail screens.
* **Permission UX**: Dynamic status cards displaying permission states (Granted, Denied, Prompt, or Windows fallback).

### 🎨 5. Customization & Preferences
* **Theme Modes**: Supports Light, Dark, and System theme preferences.
* **Display Settings**: Toggle calorie visibility, cooking time badges, default serving quantities, and case-insensitive search.

---

## 🏗️ Architecture & Project Structure

The project follows a clean repository and provider architecture:

```
lib/
├── main.dart                       # App entry point, Firebase init & AuthWrapper routing
├── firebase_options.dart           # Firebase configuration across platforms
├── models/                         # Immutable data models & Firestore serializers
│   ├── app_preferences.dart        # User settings & layout preferences
│   ├── food_category.dart          # Recipe category model
│   ├── recipe.dart                 # Recipe model with safe array coercion & instructions
│   ├── review.dart                 # Review & rating model
│   ├── shopping_list_item.dart     # Shopping list model with toggleable status
│   └── recently_viewed.dart        # Recently viewed history model
├── providers/                      # State management layer (ChangeNotifiers)
│   ├── auth_provider.dart          # Authentication state & error mapping
│   ├── preferences_provider.dart   # Real-time user preferences
│   ├── recipe_provider.dart        # Recipe streaming, search, filters & servings
│   ├── review_provider.dart        # Review submissions & stream listeners
│   ├── shopping_list_provider.dart # Shopping list item management
│   └── recently_viewed_provider.dart # Recipe viewing history
├── repositories/                   # Data access layer (Firestore & Auth abstractions)
│   ├── auth_repository.dart        # Firebase Auth & Google Sign-In implementation
│   ├── preferences_repository.dart # Firestore user preferences CRUD
│   ├── recipe_repository.dart      # Recipe & category stream queries
│   └── review_repository.dart      # Reviews index & aggregate calculation
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

### Public Collections
* `recipes/{recipeId}`: Public read-only catalog with restricted aggregate updates (`rating`, `review`, `viewCount`).
* `categories/{categoryId}`: Public read-only category items.

### User-Scoped Subcollections (`users/{uid}`)
All user-specific collections require authenticated user matching (`request.auth.uid == uid`):
* `users/{uid}`: Profile details (`displayName`, `email`, `photoUrl`, `provider`, `createdAt`).
* `users/{uid}/favorites/{recipeId}`: User's favorited recipes.
* `users/{uid}/preferences/settings`: Theme and notification preferences.
* `users/{uid}/shoppingList/{itemId}`: User's shopping list items.
* `users/{uid}/recentlyViewed/{recipeId}`: Recently viewed recipes sorted by timestamp.
* `users/{uid}/reviews/{recipeId}`: User's submitted reviews.
* `users/{uid}/notification_tokens/{tokenId}`: FCM device tokens for multi-device push delivery.

---

## 🚀 Getting Started

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.22.0 or higher)
* [Node.js](https://nodejs.org/) (for running the sample data seed script)
* [Firebase CLI](https://firebase.google.com/docs/cli) & [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

### 2. Firebase Configuration
1. Create a Firebase Project on the [Firebase Console](https://console.firebase.google.com/) (Compatible with the free **Spark Plan**).
2. Enable **Authentication** with **Email/Password** and **Google** providers.
3. Enable **Cloud Firestore** (in Production mode).
4. Run FlutterFire CLI to link your project:
   ```bash
   flutterfire configure
   ```
5. Deploy Firestore Security Rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 3. Google Sign-In Setup
* **Android**: Add your debug and release SHA-1 and SHA-256 fingerprints to your Android app settings in the Firebase Console:
  * **SHA-1**: `38:32:0C:8E:D9:E8:15:70:8A:4A:8F:D1:17:08:C0:34:8E:A1:B9:4D`
  * **SHA-256**: `F8:8D:49:A9:49:AC:60:77:C5:CA:08:88:4B:8A:01:01:8B:CF:80:13:02:49:FD:6D:CA:F9:36:3F:F7:1A:D3:37`
* **Web**:
  1. In the [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials), select your Web Client ID.
  2. Add `http://localhost` and `http://localhost:5555` to **Authorized JavaScript origins**.
  3. Ensure `https://<YOUR-PROJECT-ID>.firebaseapp.com/__/auth/handler` is in **Authorized redirect URIs**.

### 4. Seed 25 Recipes into Firestore
To seed the Firestore database with the 25 recipes:
1. Download a private service account key from **Firebase Console -> Project Settings -> Service Accounts -> Generate new private key**.
2. Save the key as `serviceAccountKey.json` in the project root directory or `sample_data/` folder.
3. Run:
   ```bash
   cd sample_data
   npm install
   node seed.js
   ```

### 5. Run the Application

#### Web (Chrome / Edge):
```bash
flutter run -d chrome
```

#### Android (USB Connected Device):
```bash
flutter run -d <device-id>
```

#### Windows Desktop:
```bash
flutter run -d windows
```

---

## 🧪 Testing & Verification

Run the full automated test suite containing 36 unit, widget, and programmatic schema validation tests:

```bash
# Static analysis
flutter analyze

# Run all test suites
flutter test

# Build release targets
flutter build web --no-tree-shake-icons
flutter build apk --debug --no-tree-shake-icons
```

---

## 🔒 Security Best Practices
* **No Hardcoded Secrets**: Sensitive API keys, OAuth client secrets, and service account files are strictly excluded via `.gitignore`.
* **Database Isolation**: Granular `firestore.rules` ensure users can only access and modify their own private subcollections.
* **Input Validation**: Defensively coerced Firestore models ensure that missing or malformed database fields never crash the UI.

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
