//self.addEventListener('install', function(event) {
//  console.log('Service worker installing...');
//  // Perform install steps
//});
//
//self.addEventListener('activate', function(event) {
//  console.log('Service worker activating...');
//});
//
//self.addEventListener('fetch', function(event) {
//  event.respondWith(
//    caches.match(event.request)
//      .then(function(response) {
//        // Cache hit - return response
//        if (response) {
//          return response;
//        }
//        return fetch(event.request);
//      }
//    )
//  );
//});


//const CACHE_NAME = 'my-site-cache-v1';
//const urlsToCache = [
//  '/',
//  '/index.html',
//  '/manifest.json',
//  '/icons/icon-192.png',
//  '/icons/icon-512.png',
//  // Add other URLs to cache here
//];
//
//// Install a service worker
//self.addEventListener('install', event => {
//  // Perform install steps
//  event.waitUntil(
//    caches.open(CACHE_NAME)
//      .then(cache => {
//        console.log('Opened cache');
//        return cache.addAll(urlsToCache);
//      })
//  );
//});
//
//// Cache and return requests
//self.addEventListener('fetch', event => {
//  event.respondWith(
//    caches.match(event.request)
//      .then(response => {
//        // Cache hit - return response
//        if (response) {
//          return response;
//        }
//        return fetch(event.request).then(
//          function(response) {
//            // Check if we received a valid response
//            if(!response || response.status !== 200 || response.type !== 'basic') {
//              return response;
//            }
//
//            // IMPORTANT: Clone the response. A response is a stream
//            // and because we want the browser to consume the response
//            // as well as the cache consuming the response, we need
//            // to clone it so we have two streams.
//            var responseToCache = response.clone();
//
//            caches.open(CACHE_NAME)
//              .then(function(cache) {
//                cache.put(event.request, responseToCache);
//              });
//
//            return response;
//          }
//        );
//      })
//  );
//});
//
//// Update a service worker
//self.addEventListener('activate', event => {
//  var cacheWhitelist = ['my-site-cache-v1'];
//  event.waitUntil(
//    caches.keys().then(cacheNames => {
//      return Promise.all(
//        cacheNames.map(cacheName => {
//          if (cacheWhitelist.indexOf(cacheName) === -1) {
//            return caches.delete(cacheName);
//          }
//        })
//      );
//    })
//  );
//});
//
//// Push notifications
//self.addEventListener('push', event => {
//  const options = {
//    body: event.data.text(),
//    icon: 'icons/icon-192.png',
//    badge: 'icons/icon-192.png'
//  };
//
//  event.waitUntil(
//    self.registration.showNotification('My PWA', options)
//  );
//});



//const CACHE_NAME = 'my-site-cache-v1';
//const urlsToCache = [
//  '/',
//  '/index.html',
//  '/manifest.json',
//  '/icons/icon-192.png',
//  '/icons/icon-512.png',
//  // Minimize initial assets to avoid timeout
//];
//
//// Install a service worker
//self.addEventListener('install', event => {
//  event.waitUntil(
//    caches.open(CACHE_NAME)
//      .then(cache => cache.addAll(urlsToCache))
//      .catch(error => console.error('Failed to open cache', error))
//  );
//});
//
//// Cache and return requests
//self.addEventListener('fetch', event => {
//  event.respondWith(
//    caches.match(event.request)
//      .then(response => response || fetch(event.request))
//  );
//});
//
//// Activate the service worker and clean up old caches
//self.addEventListener('activate', event => {
//  const cacheWhitelist = [CACHE_NAME];
//  event.waitUntil(
//    caches.keys().then(cacheNames =>
//      Promise.all(
//        cacheNames.map(cacheName => {
//          if (!cacheWhitelist.includes(cacheName)) {
//            return caches.delete(cacheName);
//          }
//        })
//      )
//    )
//  );
//});
//
//// Push notifications
//self.addEventListener('push', event => {
//  const options = {
//    body: event.data.text(),
//    icon: 'icons/icon-192.png',
//    badge: 'icons/icon-192.png'
//  };
//
//  event.waitUntil(
//    self.registration.showNotification('My PWA', options)
//  );
//});


const CACHE_NAME = 'my-site-cache-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
];

// Install a service worker
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
      .catch(error => console.error('Failed to open cache', error))
  );
});

// Cache and return requests
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});

// Activate the service worker and clean up old caches
self.addEventListener('activate', event => {
  const cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then(cacheNames =>
      Promise.all(
        cacheNames.map(cacheName => {
          if (!cacheWhitelist.includes(cacheName)) {
            return caches.delete(cacheName);
          }
        })
      )
    )
  );
});

// Push notifications
self.addEventListener('push', event => {
  const options = {
    body: event.data.text(),
    icon: 'icons/icon-192.png',
    badge: 'icons/icon-192.png'
  };

  event.waitUntil(
    self.registration.showNotification('My PWA', options)
  );
});
