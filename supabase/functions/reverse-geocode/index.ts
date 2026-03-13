// Reverse geocode lat/lng to a full address via Google Geocoding API.
// Use so "Use current location" shows street-level address, not just city/country.

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GOOGLE_BASE = "https://maps.googleapis.com/maps/api";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }

  const apiKey = Deno.env.get("GOOGLE_MAPS_API_KEY");
  if (!apiKey) {
    console.error("GOOGLE_MAPS_API_KEY is not set");
    return new Response(
      JSON.stringify({ status: "ERROR", error_message: "Reverse geocode not configured" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }

  try {
    const body = (await req.json()) as { latitude?: number; longitude?: number };
    const lat = typeof body?.latitude === "number" ? body.latitude : NaN;
    const lng = typeof body?.longitude === "number" ? body.longitude : NaN;

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return new Response(
        JSON.stringify({ status: "INVALID_REQUEST", error_message: "latitude and longitude required" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    const url = `${GOOGLE_BASE}/geocode/json?latlng=${lat},${lng}&key=${apiKey}`;

    const resp = await fetch(url, { method: "GET" });
    const data = (await resp.json()) as { status: string; results?: { formatted_address?: string }[] };

    if (data.status !== "OK" || !Array.isArray(data.results) || data.results.length === 0) {
      return new Response(JSON.stringify({ status: data.status ?? "ZERO_RESULTS", formatted_address: null }), {
        status: 200,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      });
    }

    // First result is typically the most specific (street-level when available).
    const formatted = data.results[0]?.formatted_address ?? null;

    return new Response(
      JSON.stringify({ status: "OK", formatted_address: formatted }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("reverse-geocode error:", e);
    return new Response(
      JSON.stringify({ status: "ERROR", error_message: String(e) }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
});
