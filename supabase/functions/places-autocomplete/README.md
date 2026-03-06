# places-autocomplete

Proxies Google Places Autocomplete so the Flutter app can call it without CORS (e.g. on web) and without exposing the API key on the client.

## Secret

Set your Google Maps API key in Supabase:

- **Dashboard** → **Project Settings** → **Edge Functions** → **Secrets**
- Add: `GOOGLE_MAPS_API_KEY` = your Google Maps API key

Ensure the key has **Places API** (and **Places API (New)** if you use it) enabled in [Google Cloud Console](https://console.cloud.google.com/apis/library).

## Deploy

```bash
supabase functions deploy places-autocomplete --no-verify-jwt
```

Use `--no-verify-jwt` so the app can call it with the anon key (e.g. before login). Restrict abuse with rate limiting or allowlisted origins if needed.
