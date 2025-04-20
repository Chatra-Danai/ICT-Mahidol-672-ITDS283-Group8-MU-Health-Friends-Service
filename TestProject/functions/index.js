// functions/index.js

// Import necessary Firebase modules
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK (only once)
admin.initializeApp();

// Define the Cloud Function triggered by new notification documents
exports.sendPushNotification = functions.firestore
  .document("/users/{userId}/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    // Get the newly created notification data
    const notificationData = snapshot.data();
    const userId = context.params.userId; // Get the user ID from the path

    if (!notificationData) {
      console.log("Notification data missing.");
      return null;
    }

    console.log(
      `New notification for user ${userId}. Title: ${notificationData.title}`
    );

    try {
      // Get the target user's main document to fetch preferences and token
      const userDocRef = admin.firestore().collection("users").doc(userId);
      const userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        console.log(`User document ${userId} not found.`);
        return null;
      }

      const userData = userDoc.data();

      // --- 1. Check User's Notification Preference ---
      const notificationsEnabled = userData.pushNotificationsEnabled ?? true; // Default to true if missing
      if (!notificationsEnabled) {
        console.log(`User ${userId} has push notifications disabled.`);
        return null; // Don't send if disabled
      }

      // --- 2. Get User's FCM Token ---
      const fcmToken = userData.fcmToken; // Assumes token is stored in this field
      if (!fcmToken) {
        console.log(`FCM token missing for user ${userId}.`);
        return null; // Cannot send without a token
      }

      // --- 3. Construct the FCM Payload ---
      const payload = {
        notification: {
          title: notificationData.title || "New Notification", // Use title from Firestore doc
          body: notificationData.body || "You have a new update.", // Use body from Firestore doc
          // Optional: Add sound, badge, click action etc.
          // sound: "default",
          // click_action: "FLUTTER_NOTIFICATION_CLICK", // For handling taps in Flutter app
        },
        // Optional: Add custom data payload if needed by your app
        // data: {
        //   notificationId: context.params.notificationId,
        //   type: notificationData.type || 'general',
        // },
      };

      // --- 4. Send the Push Notification using FCM ---
      console.log(`Sending FCM notification to token: ${fcmToken}`);
      const response = await admin.messaging().sendToDevice(fcmToken, payload);

      // Optional: Handle response, check for errors, cleanup invalid tokens
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          console.error(
            "Failure sending notification to",
            fcmToken, // In multi-device scenarios, you'd map tokens to results
            error
          );
          // Potentially remove invalid tokens from Firestore here
          if (
            error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered"
          ) {
            // Consider removing the invalid token from the user's document
            // userDocRef.update({ fcmToken: FieldValue.delete() }); // Or handle lists/maps of tokens
          }
        } else {
          console.log(
            "Successfully sent notification with message ID:",
            result.messageId
          );
        }
      });

      return null; // Indicate successful execution (or handle errors)
    } catch (error) {
      console.error("Error sending push notification:", error);
      return null; // Indicate failure
    }
  }
);