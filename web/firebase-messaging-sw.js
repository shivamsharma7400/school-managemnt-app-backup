importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// We need to initialize Firebase here so the background handler works
// You need to replace these values with your actual Firebase project config
// Found in your Firebase Console > Project Settings > General > Web App
firebase.initializeApp({
    apiKey: "AIzaSyAQpX0HohwKSGAqv_63qzQk1yHOwcRkalQ",
    appId: "1:32642765074:web:5ae7469d150fd0f692e3cb",
    messagingSenderId: "32642765074",
    projectId: "veena-public-school-app",
    authDomain: "veena-public-school-app.firebaseapp.com",
    storageBucket: "veena-public-school-app.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
