importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDOPO-46knmNVsn_1SWJDQ-9sTUhw2WMB0',
  authDomain: 'jawda-care.firebaseapp.com',
  projectId: 'jawda-care',
  storageBucket: 'jawda-care.firebasestorage.app',
  messagingSenderId: '320333821419',
  appId: '1:320333821419:web:b64602ca6c52a1ae9f55ae',
});

const messaging = firebase.messaging();
