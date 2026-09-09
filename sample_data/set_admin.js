/**
 * Script to assign 'admin: true' custom claim to a Firebase Authentication user.
 *
 * Usage:
 *   node sample_data/set_admin.js <user-email-or-uid>
 *
 * Prerequisites:
 *   1. Place serviceAccountKey.json in the project root or sample_data/ directory.
 *   2. Run `npm install firebase-admin`
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let serviceAccount;
const paths = [
  path.join(__dirname, 'serviceAccountKey.json'),
  path.join(__dirname, '..', 'serviceAccountKey.json'),
];

for (const p of paths) {
  if (fs.existsSync(p)) {
    serviceAccount = require(p);
    break;
  }
}

if (!serviceAccount) {
  console.error('❌ Error: serviceAccountKey.json not found in sample_data/ or root.');
  console.error('Please download your Service Account Key from Firebase Console -> Project Settings -> Service Accounts.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function setAdminClaim(identifier) {
  try {
    let userRecord;
    if (identifier.includes('@')) {
      userRecord = await admin.auth().getUserByEmail(identifier);
    } else {
      userRecord = await admin.auth().getUser(identifier);
    }

    // Set custom claim
    await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });

    console.log(`\n======================================================`);
    console.log(`✅ SUCCESS: Admin custom claim set for user!`);
    console.log(`------------------------------------------------------`);
    console.log(`UID:   ${userRecord.uid}`);
    console.log(`Email: ${userRecord.email}`);
    console.log(`Claims: { admin: true }`);
    console.log(`======================================================`);
    console.log(`\n💡 Note: If the user is currently signed in to the app,`);
    console.log(`they must log out and log back in (or force token reload)`);
    console.log(`to receive the new Admin privileges.\n`);
    process.exit(0);
  } catch (error) {
    console.error(`❌ Failed to set admin claim:`, error.message);
    process.exit(1);
  }
}

const targetUser = process.argv[2];
if (!targetUser) {
  console.log('Usage: node sample_data/set_admin.js <user-email-or-uid>');
  process.exit(1);
}

setAdminClaim(targetUser);
