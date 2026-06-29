# Hosting legal pages with clean URLs

Use these public URLs (no `.html` in the address bar):

- `https://lottoerunners.com/privacy-policy`
- `https://lottoerunners.com/terms-of-service`
- `https://lottoerunners.com/delete-account` (Google Play **Delete account URL**)

The files on the server stay named `*.html` on disk, but visitors use **short URLs without `.html`**. The `.htaccess` file rewrites those paths and **redirects** `delete-account.html` → `delete-account` (same for privacy and terms).

**Important:** If `https://lottoerunners.com/delete-account.html` works but `https://lottoerunners.com/delete-account` does not, re-upload **`docs/.htaccess`** to your site root (overwrite the old file).

## 1. Upload the HTML files

Copy to your site root (same folder as your main site `index.html`):

- `docs/privacy-policy.html`
- `docs/terms-of-service.html`
- `docs/delete-account.html`
- `docs/.htaccess` (if your host uses Apache / cPanel)

## 2. Enable clean URLs on your host

### cPanel / Apache (most common)

1. Upload `docs/.htaccess` next to the HTML files (overwrite any older `.htaccess` in that folder).
2. In cPanel, ensure **mod_rewrite** is enabled (usually on by default).
3. Test all three clean URLs (no `.html` in the address bar):
   - `https://lottoerunners.com/privacy-policy`
   - `https://lottoerunners.com/terms-of-service`
   - `https://lottoerunners.com/delete-account`
4. Visiting `https://lottoerunners.com/delete-account.html` should **redirect** to `https://lottoerunners.com/delete-account`.

### Netlify

Add redirects in `netlify.toml` **above** the SPA `/*` rule (see project `netlify.toml`). Copy `privacy-policy.html` and `terms-of-service.html` into the published folder (e.g. `build/web/` after Flutter build, or a static site root).

### Nginx

```nginx
location = /privacy-policy {
    try_files /privacy-policy.html =404;
}
location = /terms-of-service {
    try_files /terms-of-service.html =404;
}
location = /delete-account {
    try_files /delete-account.html =404;
}
```

## 3. App and Google Play

After the short URLs work in a browser, use them everywhere:

- Google Play → **Privacy policy**: `https://lottoerunners.com/privacy-policy`
- Google Play → **Delete account URL**: `https://lottoerunners.com/delete-account`
- App: `lib/constants/legal_urls.dart` (already set to these paths)

## 4. Re-upload after edits

When you change policy text, edit `docs/PRIVACY_POLICY.md` / `docs/TERMS_OF_SERVICE.md`, sync `docs/*.html`, then upload the HTML files again. Keep `.htaccess` on the server.
