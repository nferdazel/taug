import "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const intervalMap: Record<string, string> = {
  "1m": "1min",
  "5m": "5min",
  "15m": "15min",
  "1h": "1h",
  "1d": "1day",
  "1w": "1week",
  "1M": "1month",
};

async function fetchFromTwelveData(
  symbol: string,
  interval: string,
  count: number,
  apiKey: string
): Promise<Array<Record<string, unknown>> | null> {
  const tdInterval = intervalMap[interval] || interval;
  const url = `https://api.twelvedata.com/time_series?symbol=${encodeURIComponent(symbol)}&interval=${tdInterval}&outputsize=${count}&apikey=${apiKey}`;
  const response = await fetch(url);
  const data = await response.json();

  if (data.code) return null;

  const values = data.values || [];
  return values
    .map((v: Record<string, string>) => ({
      date: v.datetime,
      open: parseFloat(v.open),
      high: parseFloat(v.high),
      low: parseFloat(v.low),
      close: parseFloat(v.close),
      volume: parseInt(v.volume || "0"),
      source: "twelve_data",
      source_label: "Twelve Data",
      latency_class: "delayed",
      is_official: false,
      is_synthetic: false,
    }))
    .reverse();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { symbol, interval, limit } = await req.json();

    if (!symbol || !interval) {
      return new Response(
        JSON.stringify({ error: "symbol and interval are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("TWELVE_DATA_API_KEY");
    const count = limit || 100;
    let candles: Array<Record<string, unknown>> | null = null;

    if (apiKey) {
      candles = await fetchFromTwelveData(symbol, interval, count, apiKey);
    }

    if (!candles) {
      return new Response(
        JSON.stringify({
          error: "No legal chart source configured for symbol",
        }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(JSON.stringify(candles), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
