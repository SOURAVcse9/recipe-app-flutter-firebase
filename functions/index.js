const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Helper to fetch all valid FCM tokens from users collection and subcollections.
 */
async function getAllUserTokens() {
  const tokens = [];
  const tokenDocRefs = [];

  const usersSnap = await admin.firestore().collection('users').get();
  for (const userDoc of usersSnap.docs) {
    const data = userDoc.data();

    // Check direct fcmToken
    if (data.fcmToken && typeof data.fcmToken === 'string') {
      tokens.push(data.fcmToken);
      tokenDocRefs.push({ ref: userDoc.ref, field: 'fcmToken' });
    }

    // Check notification_tokens subcollection
    const tokensSubSnap = await userDoc.ref.collection('notification_tokens').get();
    for (const tokenDoc of tokensSubSnap.docs) {
      const token = tokenDoc.data().token || tokenDoc.id;
      if (token && typeof token === 'string') {
        tokens.push(token);
        tokenDocRefs.push({ ref: tokenDoc.ref, isSubDoc: true });
      }
    }
  }

  // Deduplicate tokens
  const uniqueTokens = [...new Set(tokens)];
  return { uniqueTokens, tokenDocRefs };
}

/**
 * Trigger: When a recipe is created or published.
 */
exports.onRecipeCreatedOrPublished = functions.firestore
  .document('recipes/{recipeId}')
  .onWrite(async (change, context) => {
    const afterData = change.after.exists ? change.after.data() : null;
    const beforeData = change.before.exists ? change.before.data() : null;

    if (!afterData) return null; // Deleted recipe

    const isNowPublished = afterData.isPublished === true;
    const wasPublished = beforeData ? beforeData.isPublished === true : false;

    // Trigger only on new published recipe OR transition from draft to published
    const isNewPublished = !beforeData && isNowPublished;
    const isJustPublished = !wasPublished && isNowPublished;

    if (!isNewPublished && !isJustPublished) {
      return null;
    }

    const recipeId = context.params.recipeId;
    const recipeName = afterData.name || 'Delicious Recipe';

    const { uniqueTokens, tokenDocRefs } = await getAllUserTokens();
    if (uniqueTokens.length === 0) {
      console.log('No registered FCM tokens found.');
      return null;
    }

    const payload = {
      notification: {
        title: 'New Recipe Added 🍽️',
        body: `${recipeName} has just been added. Check it out!`,
      },
      data: {
        recipeId: recipeId,
        type: 'recipe_detail',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    const response = await admin.messaging().sendEachForMulticast({
      tokens: uniqueTokens,
      notification: payload.notification,
      data: payload.data,
    });

    console.log(`Successfully sent ${response.successCount} recipe notifications.`);

    // Token cleanup for invalid tokens
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errCode = resp.error?.code;
          if (
            errCode === 'messaging/invalid-registration-token' ||
            errCode === 'messaging/registration-token-not-registered'
          ) {
            const badToken = uniqueTokens[idx];
            console.log(`Cleaning invalid token: ${badToken}`);
          }
        }
      });
    }

    return null;
  });

/**
 * Trigger: When a new active category is created.
 */
exports.onCategoryCreated = functions.firestore
  .document('categories/{categoryId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data || data.isActive === false) return null;

    const categoryName = data.name || 'New Category';
    const { uniqueTokens } = await getAllUserTokens();
    if (uniqueTokens.length === 0) return null;

    const payload = {
      notification: {
        title: 'New Category Added',
        body: `${categoryName} recipes are now available!`,
      },
      data: {
        category: categoryName,
        type: 'category',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    const response = await admin.messaging().sendEachForMulticast({
      tokens: uniqueTokens,
      notification: payload.notification,
      data: payload.data,
    });

    console.log(`Successfully sent ${response.successCount} category notifications.`);
    return null;
  });
