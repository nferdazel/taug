import "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://taug.vercel.app",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SnapshotTarget {
  symbolId: number;
  ticker: string;
  vendorSymbol: string;
  vendor: string;
}

async function fetchFromTwelveData(
  symbol: string,
  apiKey: string,
): Promise<Record<string, unknown> | null> {
  const url =
    `https://api.twelvedata.com/quote?symbol=${encodeURIComponent(symbol)}&apikey=${apiKey}`;
  const response = await fetch(url);

  if (!response.ok) {
    return null;
  }

  const data = await response.json();
  if (data.code) {
    return null;
  }

  const asOf = data.timestamp
    ? new Date(data.timestamp * 1000).toISOString()
    : new Date().toISOString();

  return {
    price: parseFloat(data.close || "0"),
    previous_close: parseFloat(data.previous_close || "0"),
    open: parseFloat(data.open || "0"),
    high: parseFloat(data.high || "0"),
    low: parseFloat(data.low || "0"),
    close: parseFloat(data.close || "0"),
    volume: parseInt(data.volume || "0"),
    turnover: parseFloat(data.turnover || "0"),
    source_vendor: "twelve_data",
    source_label: "Twelve Data",
    latency_class: "delayed",
    source_url: "https://api.twelvedata.com/quote",
    is_official: false,
    is_synthetic: false,
    fetched_at: new Date().toISOString(),
    as_of: asOf,
    updated_at: new Date().toISOString(),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUser = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("TWELVE_DATA_API_KEY");

    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "TWELVE_DATA_API_KEY is not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      db: { schema: "taug" },
    });

    const body =
      req.method === "POST" ? await req.json().catch(() => ({})) : {};
    const requestedTickers = Array.isArray(body.tickers)
      ? body.tickers.filter((value: unknown): value is string =>
        typeof value === "string"
      )
      : <string[]>[];
    const limit = typeof body.limit === "number" ? body.limit : 100;

    let query = supabase
      .from("symbols")
      .select(`
        id,
        ticker,
        instrument_sources(
          vendor,
          vendor_symbol,
          is_primary,
          is_active
        )
      `)
      .eq("is_active", true)
      .limit(limit);

    if (requestedTickers.length > 0) {
      query = query.in("ticker", requestedTickers);
    }

    const { data, error } = await query;
    if (error) {
      throw error;
    }

    const targets: SnapshotTarget[] = (data ?? []).map((row) => {
      const sources = Array.isArray(row.instrument_sources)
        ? row.instrument_sources
        : [];
      const primary = sources.find((source) =>
        source.is_primary === true && source.is_active !== false
      );
      const primaryVendorSymbol = typeof primary?.vendor_symbol === "string"
        ? primary.vendor_symbol
        : row.ticker as string;
      const primaryVendor = typeof primary?.vendor === "string"
        ? primary.vendor
        : "twelve_data";

      return {
        symbolId: row.id as number,
        ticker: row.ticker as string,
        vendorSymbol: primaryVendorSymbol,
        vendor: primaryVendor,
      };
    }).filter((target) => target.vendor === "twelve_data");

    const refreshed = await Promise.all(
      targets.map(async (target) => {
        try {
          const quote = await fetchFromTwelveData(target.vendorSymbol, apiKey);
          if (quote == null) {
            return null;
          }

          return {
            symbol_id: target.symbolId,
            ...quote,
          };
        } catch (error) {
          console.error(`[refresh-quote-snapshots] ${target.ticker}:`, error);
          return null;
        }
      }),
    );

    const upserts = refreshed.filter((item) => item !== null);
    if (upserts.length > 0) {
      const { error: upsertError } = await supabase
        .from("quote_snapshots")
        .upsert(upserts, { onConflict: "symbol_id" });

      if (upsertError) {
        throw upsertError;
      }
    }

    return new Response(
      JSON.stringify({
        requested: targets.length,
        refreshed: upserts.length,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
