const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Recalculate handicap index when a new handicap record is added.
 * Uses USGA/WHS rules: best 8 of last 20 differentials.
 */
exports.recalculateHandicap = onDocumentWritten(
  "handicapRecords/{recordId}",
  async (event) => {
    const data = event.data.after.data();
    if (!data) return;

    const userID = data.userID;
    const records = await db
      .collection("handicapRecords")
      .where("userID", "==", userID)
      .orderBy("date", "desc")
      .limit(20)
      .get();

    const differentials = records.docs.map((d) => d.data().scoreDifferential);
    if (differentials.length < 3) return;

    const sorted = [...differentials].sort((a, b) => a - b);
    const count = sorted.length;
    let usedCount, adjustment;

    if (count <= 5) {
      usedCount = 1;
      adjustment = count === 3 ? -2.0 : count === 4 ? -1.0 : 0.0;
    } else if (count <= 8) {
      usedCount = 2;
      adjustment = count === 6 ? -1.0 : 0.0;
    } else if (count <= 10) {
      usedCount = 3;
      adjustment = 0.0;
    } else if (count <= 12) {
      usedCount = 4;
      adjustment = 0.0;
    } else if (count <= 14) {
      usedCount = 5;
      adjustment = 0.0;
    } else if (count <= 16) {
      usedCount = 6;
      adjustment = 0.0;
    } else if (count <= 18) {
      usedCount = 7;
      adjustment = 0.0;
    } else {
      usedCount = 8;
      adjustment = 0.0;
    }

    const best = sorted.slice(0, usedCount);
    const avg = best.reduce((s, v) => s + v, 0) / usedCount;
    let index = Math.min(avg + adjustment, 54.0);
    index = Math.round(index * 10) / 10;

    await db.collection("users").doc(userID).update({
      handicapIndex: index,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);

/**
 * Calculate final game settlements when a round is completed.
 */
exports.calculateSettlement = onDocumentWritten(
  "rounds/{roundId}",
  async (event) => {
    const data = event.data.after.data();
    if (!data || data.status !== "completed" || data.moneyPot?.isSettled) return;

    // Settlements are calculated client-side in MoneyViewModel
    // This function could do additional validation or logging
    console.log(`Round ${event.params.roundId} completed with ${data.playerIDs.length} players`);
  }
);

/**
 * Clean up user data on account deletion.
 */
exports.cleanupUser = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

  const batch = db.batch();

  // Delete handicap records
  const records = await db
    .collection("handicapRecords")
    .where("userID", "==", uid)
    .get();
  records.forEach((doc) => batch.delete(doc.ref));

  // Remove from friends lists
  const user = await db.collection("users").doc(uid).get();
  const friendIDs = user.data()?.friendIDs || [];
  for (const fid of friendIDs) {
    batch.update(db.collection("users").doc(fid), {
      friendIDs: admin.firestore.FieldValue.arrayRemove(uid),
    });
  }

  // Delete user profile
  batch.delete(db.collection("users").doc(uid));

  await batch.commit();
  return { success: true };
});
