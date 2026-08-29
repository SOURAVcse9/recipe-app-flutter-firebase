/**
 * One-time seed script — uploads assets/data/recipe_firebase_seed.json
 * into Firestore using the Admin SDK.
 *
 * Setup:
 *   1. npm install
 *   2. Download a service account key from Project Settings -> Service Accounts -> Generate new private key
 *   3. Save it as serviceAccountKey.json in the project root or sample_data/ directory.
 *   4. Run: npm run seed
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const data = require('../assets/data/recipe_firebase_seed.json');

let serviceAccountPath;
const localPath = path.join(__dirname, 'serviceAccountKey.json');
const rootPath = path.join(__dirname, '..', 'serviceAccountKey.json');

if (fs.existsSync(localPath)) {
  serviceAccountPath = localPath;
} else if (fs.existsSync(rootPath)) {
  serviceAccountPath = rootPath;
} else {
  console.error('\n[ERROR] serviceAccountKey.json is missing!');
  console.log('To resolve this:');
  console.log('1. Open Firebase Console -> Project Settings -> Service Accounts.');
  console.log('2. Click "Generate new private key" to download the JSON credentials.');
  console.log('3. Save the downloaded file as "serviceAccountKey.json" in this project root.');
  console.log('4. Run "npm run seed" again.\n');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const RECIPES_COLLECTION = 'recipes';
const CATEGORIES_COLLECTION = 'categories';

async function seed() {
  console.log('Seeding categories...');
  const categories = data.categories;
  const categoryKeys = Object.keys(categories);
  for (const key of categoryKeys) {
    const docRef = db.collection(CATEGORIES_COLLECTION).doc(key);
    await docRef.set(categories[key], { merge: true });
    console.log(`  ${key} -> uploaded`);
  }
  console.log(`${categoryKeys.length} categories uploaded successfully.\n`);

  console.log('Seeding recipes...');
  const recipes = data.recipes;
  const recipeKeys = Object.keys(recipes);
  for (const key of recipeKeys) {
    const docRef = db.collection(RECIPES_COLLECTION).doc(key);
    await docRef.set(recipes[key], { merge: true });
    console.log(`  ${key} -> uploaded`);
  }
  console.log(`${recipeKeys.length} recipes uploaded successfully.`);
}

seed().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
