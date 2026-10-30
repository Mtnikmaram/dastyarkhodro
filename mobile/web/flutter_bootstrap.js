{{flutter_js}}
{{flutter_build_config}}

// Disable Flutter's generated service worker so stale cached builds cannot
// leave the PWA with mismatched assets after a deployment.
_flutter.loader.load({config: {serviceWorkerSettings: null}});
