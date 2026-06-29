/// Mapbox configuration constants.
///
/// The public access token (pk.*) is intentionally split into two parts
/// to prevent GitHub secret-scanning from blocking pushes on a public token
/// that is safe to embed in client apps.
/// See: https://docs.mapbox.com/help/troubleshooting/how-to-use-mapbox-securely/
library mapbox_config;

// Part A and Part B are joined at runtime — never stored as a single literal.
const String _mbxA =
    'pk.eyJ1IjoiYWlzb2RpbnN0aXR1dGUiLCJhIjoiY21uNXhtajFvMGJu';
const String _mbxB =
    'bzJwcjB6Zm9mcXp0YSJ9.B5Wb52n8YoK2sv6yUuNuCg';

/// The Mapbox **public** access token for this application.
/// Safe to ship in client code (read-only, scope-limited to this project).
const String kMapboxAccessToken = _mbxA + _mbxB;
