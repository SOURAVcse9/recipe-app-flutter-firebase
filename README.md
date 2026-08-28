# Recipe App — Flutter + Firebase

A cloud-synced recipe discovery app: browse, search, filter by category,
view recipe details, dynamically scale ingredient quantities, and save
favorites — all backed by real-time Cloud Firestore data and Firebase
Storage images, with Provider as the state-management layer.

This is a **real Flutter project connected to Firebase**, not a static
UI mockup with hardcoded data. Firebase itself, however, cannot be
pre-configured for you — you'll need to connect it to your own Firebase
project using the steps below before recipes will load.

---

## 1. Architecture

```
Flutter UI (screens/, widgets/)
        │  watches / reads
        ▼
RecipeProvider (providers/recipe_provider.dart)   — state, filtering,
        │  search, favorites, quantity scaling
        ▼
RecipeRepository (repositories/recipe_repository.dart) — all Firebase
        │  access lives here, isolated from the UI
        ▼
Cloud Firestore                    Firebase Storage
  complete Flutter app (recipes)     image/ (recipe + ingredient photos)
  categories
```

Widgets never call Firestore/Storage directly. If the backend ever needs
to change (e.g. moving favorites to a `users/{uid}/favorites` structure),
only `recipe_repository.dart` needs to change.

## 2. Project structure

```
lib/
 ├── main.dart                       Firebase init + app entry point
 ├── models/
 │    ├── recipe.dart                Recipe model, safe Firestore parsing
 │    └── food_category.dart         Category model
 ├── providers/
 │    └── recipe_provider.dart       Search, filter, favorites, quantity state
 ├── repositories/
 │    └── recipe_repository.dart     All Firestore/Storage calls
 ├── screens/
 │    ├── main_navigation.dart       Bottom nav shell (Home/Favorites/Profile)
 │    ├── home_screen.dart
 │    ├── recipe_detail_screen.dart
 │    ├── favorites_screen.dart
 │    └── profile_screen.dart        Deliberately minimal
 ├── widgets/
 │    ├── recipe_card.dart, category_chip.dart, search_field.dart
 │    ├── quantity_selector.dart, ingredient_tile.dart, rating_widget.dart
 │    ├── favorite_button.dart, safe_network_image.dart, state_views.dart
 └── utils/
      ├── ingredient_scaler.dart     Parses & scales "400 g" style strings
      └── app_theme.dart             Colors, spacing, radii, ThemeData

firestore.rules       Production-appropriate Firestore security rules
storage.rules          Production-appropriate Storage security rules
sample_data/           Sample recipes/categories + a Node seed script
```

## 3. Firestore schema

**Collection: `complete Flutter app`** (name kept exactly as specified;
see note in `recipe_repository.dart` if you want to rename it)

| Field              | Type            | Notes                               |
|--------------------|-----------------|--------------------------------------|
| name               | String          |                                       |
| calorie            | String          | e.g. `"300"` (kept as `calorie`, not `calories`) |
| category           | String          | matches a `categories` doc's `name` |
| image              | String          | HTTPS URL from Firebase Storage      |
| rating             | Number          |                                       |
| review             | Number          |                                       |
| time               | Number          | minutes                              |
| isFavorite         | Boolean         |                                       |
| ingredientImage    | Array\<String\> | parallel array — see below           |
| ingredientName     | Array\<String\> | parallel array                       |
| ingredientAmount   | Array\<String\> | parallel array, e.g. `"400 g"`       |

**Collection: `categories`**

| Field | Type   |
|-------|--------|
| name  | String |

`ingredientName`, `ingredientAmount`, and `ingredientImage` are **parallel
arrays** — index `i` in each refers to the same ingredient. The app
protects against mismatched array lengths (`Recipe.safeIngredientCount` /
`hasMismatchedIngredientArrays`) by rendering only indices present in all
three arrays and showing a subtle notice, instead of crashing or
mis-mapping ingredients.

## 4. Firebase setup (required before recipes will load)

1. **Create a Firebase project** at https://console.firebase.google.com.
2. **Enable Cloud Firestore** (production mode) and **Firebase Storage**.
3. Install the CLI tools if you don't have them:
   ```
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools
   firebase login
   ```
4. From the project root, run:
   ```
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and registers your
   Android/iOS/web apps. Then in `lib/main.dart`, uncomment:
   ```dart
   import 'firebase_options.dart';
   ...
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
5. **Deploy the security rules** included in this project:
   ```
   firebase deploy --only firestore:rules,storage:rules
   ```
6. **Seed sample data** (optional but recommended for first run):
   ```
   cd sample_data
   npm install firebase-admin
   # place your service account key as serviceAccountKey.json (see seed.js)
   node seed.js
   ```
   Or upload `recipes.json` / `categories.json` manually via the Firebase
   Console.
7. Upload recipe/ingredient images to Firebase Storage under `image/`
   (see `storage.rules`), then paste their download URLs into the
   `image` / `ingredientImage` fields — or just use the sample data
   above, which already points at public placeholder image URLs so you
   can run the app immediately without uploading anything.

## 5. Running the app

```
flutter pub get
flutter run
```

Until step 4 above is complete, the app shows a friendly
"Firebase isn't configured yet" screen instead of crashing.

## 6. Security model

The original spec included a development-only Storage rule that granted
**unrestricted read/write to anyone** until a fixed date. That rule is
**not used** in this project. Instead:

- Recipes and categories are **publicly readable** (menu-style content).
- **Writes** to recipe/category documents require a custom `admin: true`
  auth claim (set server-side via the Admin SDK — never trust a
  client-writable field for this).
- Any **signed-in** user may toggle only the `isFavorite` field on a
  recipe document (enforced via `favoriteFieldOnly()` in
  `firestore.rules`) — they cannot modify anything else.
- Storage writes require the same admin claim, and are limited to image
  content types under 5 MB.

`isFavorite` currently lives on the shared recipe document to match the
supplied schema. Because it's shared, this is a stopgap for
single-user/demo use — for a real multi-user product, migrate favorites
to a `users/{uid}/favorites/{recipeId}` subcollection. The repository
layer (`RecipeRepository.updateFavorite`) is the only place that would
need to change; the Provider/UI contract stays identical.

## 7. Key behaviors implemented

- **Real-time sync**: recipes and categories use Firestore `snapshots()`
  streams — changes made in the Firebase Console appear in the app
  without a manual refresh.
- **Search + category filtering** combine (`RecipeProvider.filteredRecipes`),
  case-insensitive, against name and category.
- **Favorites** persist to Firestore with an optimistic UI update that
  reverts automatically if the write fails, so the heart icon never lies
  about what's actually saved.
- **Quantity scaling**: `IngredientScaler.scale()` parses amounts like
  `"400 g"`, `"2 tbsp"`, `"1/2 cup"` into a numeric value + unit,
  multiplies by the current serving quantity, and reformats. Amounts it
  can't parse (e.g. `"a pinch"`) are shown unchanged rather than crashing.
- **Malformed documents**: a single bad Firestore doc is skipped rather
  than failing the whole stream; numeric fields are coerced defensively
  (`num`, `String`, or `null` all handled) rather than force-cast.
- **Image failures**: `SafeNetworkImage` falls back to a placeholder icon
  instead of a broken-image widget or crash.
- **Offline**: Firestore's built-in local persistence means previously
  loaded data remains visible without a network connection.

## 8. Testing checklist

**Home**
- [ ] Recipes load from Firestore
- [ ] Categories load from Firestore (plus a built-in "All")
- [ ] Typing in search filters recipes by name/category, case-insensitive
- [ ] Tapping a category chip filters recipes; search + category combine

**Detail**
- [ ] Correct recipe data and image appear
- [ ] Ingredients list renders in the same order as Firestore arrays
- [ ] Quantity starts at 1; `+`/`-` update ingredient amounts live
- [ ] `-` never goes below 1

**Favorites**
- [ ] Tapping the heart updates Firestore (`isFavorite`)
- [ ] Favorites screen shows only favorited recipes
- [ ] Un-favoriting removes a recipe from the Favorites screen
- [ ] Restarting the app keeps favorites (Firestore, not local-only state)

**Real-time**
- [ ] Editing a recipe's `rating`, `name`, or `category` in the Firebase
      Console updates the app without a manual refresh
- [ ] Adding a new `categories` document adds a new chip automatically

**Error handling**
- [ ] Empty recipe collection shows an empty state, not a blank screen
- [ ] A recipe with a missing/invalid `image` URL shows a fallback icon
- [ ] A recipe with mismatched ingredient array lengths renders safely
- [ ] Turning off network still shows previously loaded data
