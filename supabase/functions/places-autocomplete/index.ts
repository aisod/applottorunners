// Proxies Google Places Autocomplete so the Flutter app can call it without CORS or exposing the API key.

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
      { status: 405, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }

  const apiKey = Deno.env.get("GOOGLE_MAPS_API_KEY");
  if (!apiKey) {
    console.error("GOOGLE_MAPS_API_KEY is not set");
    return new Response(
      JSON.stringify({ status: "ERROR", error_message: "Places proxy not configured" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }

  try {
    const body = await req.json() as { query?: string; country?: string; types?: string };
    const query = typeof body?.query === "string" ? body.query.trim() : "";
    const country = typeof body?.country === "string" && body.country.length === 2
      ? body.country.toLowerCase()
      : "na";
    const types = typeof body?.types === "string" && body.types.length > 0
      ? body.types
      : "geocode";

    if (!query) {
      return new Response(
        JSON.stringify({ status: "INVALID_REQUEST", error_message: "query is required" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const input = encodeURIComponent(query);
    const url = `${GOOGLE_BASE}/place/autocomplete/json?input=${input}&key=${apiKey}&components=country:${country}&types=${encodeURIComponent(types)}`;

    const resp = await fetch(url, { method: "GET" });
    const data = await resp.json();

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("places-autocomplete error:", e);
    return new Response(
      JSON.stringify({ status: "ERROR", error_message: String(e) }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
