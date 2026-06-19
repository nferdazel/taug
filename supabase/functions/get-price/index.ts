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
  };
}

async function fetchFromYahoo(symbol: string): Promise<Record<string, unknown> | null> {
  const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(symbol)}?interval=1d&range=1d`;
  const response = await fetch(url, {
    headers: { "User-Agent": "Taug/1.0" },
  });

  if (!response.ok) return null;

  const data = await response.json();
  const result = data?.chart?.result?.[0];
  if (!result) return null;

  const meta = result.meta;
  return {
    symbol: meta.symbol,
    price: meta.regularMarketPrice || 0,
    previous_close: meta.previousClose || meta.chartPreviousClose || 0,
    open: meta.regularMarketOpen || 0,
    high: meta.regularMarketDayHigh || 0,
    low: meta.regularMarketDayLow || 0,
    volume: meta.regularMarketVolume || 0,
    turnover: 0,
    last_update: new Date().toISOString(),
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

    if (!result && symbol.includes(".JK")) {
      result = await fetchFromYahoo(symbol);
    }

    if (!result && apiKey) {
      result = await fetchFromYahoo(symbol);
    }

    if (!result) {
      return new Response(
        JSON.stringify({ error: "No data found for symbol" }),
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
