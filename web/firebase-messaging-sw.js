importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing the messagingSenderId.
// This is the public sender ID from the firebase_options.dart.
firebase.initializeApp({
  apiKey: "AIzaSyADigk1PH6LBs0QMV-Zu_vwid09vQ99Jv0",
  authDomain: "recipe-app-81189.firebaseapp.com",
  projectId: "recipe-app-81189",
  storageBucket: "recipe-app-81189.firebasestorage.app",
  messagingSenderId: "425044932718",
  appId: "1:425044932718:web:f951e043d2170e77574e7f",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
