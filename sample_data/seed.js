/**
 * One-time seed script — uploads sample_data/recipes.json and
 * sample_data/categories.json into Firestore using the Admin SDK
 * (Admin SDK bypasses security rules, so this works even with the
 * locked-down rules.rules shipped in this project).
 *
 * Setup:
 *   1. npm install firebase-admin
 *   2. Download a service account key from:
 *      Firebase Console -> Project Settings -> Service Accounts
 *      -> Generate new private key
 *      Save it as ./serviceAccountKey.json (DO NOT COMMIT THIS FILE)
 *   3. node seed.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const recipes = require('./recipes.json');
const categories = require('./categories.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Matches RecipeRepository.recipesCollection in the Flutter app.
const RECIPES_COLLECTION = 'complete Flutter app';
const CATEGORIES_COLLECTION = 'categories';

async function seed() {
  const batch = db.batch();

  recipes.forEach((recipe) => {
    const ref = db.collection(RECIPES_COLLECTION).doc();
    batch.set(ref, recipe);
  });

  categories.forEach((category) => {
    const ref = db.collection(CATEGORIES_COLLECTION).doc();
    batch.set(ref, category);
  });

  await batch.commit();
  console.log(
    `Seeded ${recipes.length} recipes and ${categories.length} categories.`
  );
}

seed().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
