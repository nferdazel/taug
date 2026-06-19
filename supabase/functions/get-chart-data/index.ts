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

const yahooIntervalMap: Record<string, string> = {
  "1m": "1m",
  "5m": "5m",
  "15m": "15m",
  "1h": "1h",
  "1d": "1d",
  "1w": "1wk",
  "1M": "1mo",
};

const yahooRangeMap: Record<string, string> = {
  "1m": "5d",
  "5m": "1mo",
  "15m": "1mo",
  "1h": "3mo",
  "1d": "1y",
  "1w": "5y",
  "1M": "max",
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
    }))
    .reverse();
}

async function fetchFromYahoo(
  symbol: string,
  interval: string,
  limit: number
): Promise<Array<Record<string, unknown>> | null> {
  const yfInterval = yahooIntervalMap[interval] || "1d";
  const range = yahooRangeMap[interval] || "1y";

  const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(symbol)}?interval=${yfInterval}&range=${range}`;
  const response = await fetch(url, {
    headers: { "User-Agent": "Taug/1.0" },
  });

  if (!response.ok) return null;

  const data = await response.json();
  const result = data?.chart?.result?.[0];
  if (!result) return null;

  const timestamps = result.timestamp || [];
  const ohlcv = result.indicators?.quote?.[0];
  if (!ohlcv) return null;

  const candles: Array<Record<string, unknown>> = [];
  for (let i = 0; i < timestamps.length; i++) {
    if (ohlcv.close[i] != null) {
      candles.push({
        date: new Date(timestamps[i] * 1000).toISOString().split("T")[0],
        open: ohlcv.open[i] || 0,
        high: ohlcv.high[i] || 0,
        low: ohlcv.low[i] || 0,
        close: ohlcv.close[i] || 0,
        volume: ohlcv.volume?.[i] || 0,
      });
    }
  }

  return candles.slice(-limit);
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
      candles = await fetchFromYahoo(symbol, interval, count);
    }

    if (!candles) {
      return new Response(
        JSON.stringify({ error: "No chart data found" }),
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
