import "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

async function fetchFromTwelveData(symbol: string, apiKey: string): Promise<Record<string, unknown> | null> {
  const url = `https://api.twelvedata.com/quote?symbol=${encodeURIComponent(symbol)}&apikey=${apiKey}`;
  const response = await fetch(url);
  const data = await response.json();

  if (data.code) return null;

  return {
    symbol: data.symbol,
    price: parseFloat(data.close || "0"),
    previous_close: parseFloat(data.previous_close || "0"),
    open: parseFloat(data.open || "0"),
    high: parseFloat(data.high || "0"),
    low: parseFloat(data.low || "0"),
    volume: parseInt(data.volume || "0"),
    turnover: parseFloat(data.turnover || "0"),
    last_update: data.timestamp
      ? new Date(data.timestamp * 1000).toISOString()
      : new Date().toISOString(),
    source: "twelve_data",
    source_label: "Twelve Data",
    latency_class: "delayed",
    is_official: false,
    is_synthetic: false,
    fetched_at: new Date().toISOString(),
    as_of: data.timestamp
      ? new Date(data.timestamp * 1000).toISOString()
      : new Date().toISOString(),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { symbol } = await req.json();

    if (!symbol) {
      return new Response(
        JSON.stringify({ error: "symbol is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("TWELVE_DATA_API_KEY");
    let result: Record<string, unknown> | null = null;

    if (apiKey) {
      result = await fetchFromTwelveData(symbol, apiKey);
    }

    if (!result) {
      return new Response(
        JSON.stringify({
          error: "No legal quote source configured for symbol",
        }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
