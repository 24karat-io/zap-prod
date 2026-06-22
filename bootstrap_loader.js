(function () {
  'use strict';

  var RELOAD_KEY = 'zap_web_reload_attempts';
  var VERIFIED_KEY = 'zap_web_bootstrap_verified';
  var MAX_RELOADS = 5;

  function isLocalDevHost() {
    var host = window.location.hostname;
    return host === 'localhost' || host === '127.0.0.1';
  }

  function loadFlutterBootstrap(buildNumber) {
    var script = document.createElement('script');
    script.src = 'flutter_bootstrap.js?v=' + encodeURIComponent(buildNumber);
    script.async = true;
    document.body.appendChild(script);
  }

  function redirectWithBuild(buildNumber) {
    var attempts = parseInt(sessionStorage.getItem(RELOAD_KEY) || '0', 10);
    if (attempts >= MAX_RELOADS) {
      console.warn('[ZAP] Max reload attempts reached, loading Flutter anyway.');
      sessionStorage.setItem(VERIFIED_KEY, buildNumber);
      loadFlutterBootstrap(buildNumber);
      return;
    }

    sessionStorage.setItem(RELOAD_KEY, String(attempts + 1));
    var url = new URL(window.location.href);
    url.searchParams.set('v', buildNumber);
    url.searchParams.set('_cb', String(Date.now()));
    window.location.replace(url.toString());
  }

  // Local `flutter run` serves version.json from pubspec but deployBuildNumber
  // is only updated on CI deploy — skip cache-bust redirects during development.
  if (isLocalDevHost()) {
    loadFlutterBootstrap('dev');
    return;
  }

  fetch('version.json?_=' + Date.now(), { cache: 'no-store' })
    .then(function (response) {
      if (!response.ok) {
        throw new Error('HTTP ' + response.status);
      }
      return response.json();
    })
    .then(function (data) {
      var buildNumber = String(data.build_number);
      var url = new URL(window.location.href);

      if (url.searchParams.get('v') !== buildNumber) {
        redirectWithBuild(buildNumber);
        return;
      }

      sessionStorage.removeItem(RELOAD_KEY);
      sessionStorage.setItem(VERIFIED_KEY, buildNumber);
      loadFlutterBootstrap(buildNumber);
    })
    .catch(function (error) {
      console.warn('[ZAP] version.json unavailable, loading Flutter anyway:', error);
      loadFlutterBootstrap('fallback');
    });
})();
