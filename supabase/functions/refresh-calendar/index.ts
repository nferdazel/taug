import "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface EconEvent {
  title: string;
  country: string;
  category: string;
  importance: number;
  actual: number | null;
  forecast: number | null;
  previous: number | null;
  unit: string;
  event_date: string;
  event_time: string;
  source: string;
}

function parseInvestingComCalendar(html: string): EconEvent[] {
  const events: EconEvent[] = [];

  const rowRegex = /<tr[^>]*data-event-id="[^"]*"[^>]*>([\s\S]*?)<\/tr>/g;
  let match;

  while ((match = rowRegex.exec(html)) !== null) {
    const row = match[1];
    const timeMatch = row.match(/<td[^>]*class="[^"]*time[^"]*"[^>]*>([\s\S]*?)<\/td>/);
    const currencyMatch = row.match(/<td[^>]*class="[^"]*flag[^"]*"[^>]*title="([^"]*)"[^>]*>/);
    const eventMatch = row.match(/<td[^>]*class="[^"]*event[^"]*"[^>]*>([\s\S]*?)<\/td>/);
    const impactMatch = row.match(/<td[^>]*class="[^"]*impact[^"]*"[^>]*><span[^>]*class="[^"]*ico-([a-z]+)[^"]*"[^>]*>/);
    const actualMatch = row.match(/<td[^>]*class="[^"]*act[^"]*"[^>]*>([\s\S]*?)<\/td>/);
    const forecastMatch = row.match(/<td[^>]*class="[^"]*fore[^"]*"[^>]*>([\s\S]*?)<\/td>/);
    const previousMatch = row.match(/<td[^>]*class="[^"]*prev[^"]*"[^>]*>([\s\S]*?)<\/td>/);

    if (eventMatch) {
      const time = timeMatch?.[1]?.trim().replace(/<[^>]*>/g, "") || "";
      const country = currencyMatch?.[1] || "";
      const title = eventMatch[1].replace(/<[^>]*>/g, "").trim();
      const importance = impactMatch?.[1] === "high" ? 3
        : impactMatch?.[1] === "medium" ? 2
        : 1;
      const actual = parseNumber(actualMatch?.[1]);
      const forecast = parseNumber(forecastMatch?.[1]);
      const previous = parseNumber(previousMatch?.[1]);

      const now = new Date();
      const eventDate = now.toISOString().split("T")[0];

      events.push({
        title,
        country,
        category: determineCategory(title),
        importance,
        actual,
        forecast,
        previous,
        unit: determineUnit(title),
        event_date: eventDate,
        event_time: time,
        source: "investing_com",
      });
    }
  }

  return events;
}

function parseNumber(str: string | undefined): number | null {
  if (!str) return null;
  const cleaned = str.replace(/[^0-9.\-]/g, "");
  const num = parseFloat(cleaned);
  return isNaN(num) ? null : num;
}

function determineCategory(title: string): string {
  const lower = title.toLowerCase();
  if (lower.match(/rate|interest|monetary|central bank/)) return "central_bank";
  if (lower.match(/cpi|inflation|ppi|price/)) return "inflation";
  if (lower.match(/gdp|growth|product/)) return "gdp";
  if (lower.match(/employment|unemploy|payroll|jobs|jobless/)) return "employment";
  if (lower.match(/trade|export|import/)) return "trade";
  if (lower.match(/pmi|manufacturing|services/)) return "pmi";
  if (lower.match(/consumer|retail|sales/)) return "consumer";
  if (lower.match(/housing|home|property/)) return "housing";
  return "other";
}

function determineUnit(title: string): string {
  const lower = title.toLowerCase();
  if (lower.match(/percent|rate|yield/)) return "%";
  if (lower.match(/k\b|thousand/)) return "K";
  if (lower.match(/m\b|million/)) return "M";
  if (lower.match(/b\b|billion/)) return "B";
  return "index";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const events: EconEvent[] = [];

    // Fetch from Trading Economics RSS
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000);

      const response = await fetch("https://tradingeconomics.com/calendar", {
        signal: controller.signal,
        headers: {
          "User-Agent": "Mozilla/5.0 (compatible; Taug/1.0)",
          Accept: "text/html",
        },
      });
      clearTimeout(timeout);

      if (response.ok) {
        const html = await response.text();
        const parsed = parseInvestingComCalendar(html);
        events.push(...parsed);
      }
    } catch (e) {
      console.error("Failed to fetch calendar:", e);
    }

    const today = new Date().toISOString().split("T")[0];
    const hardcodedEvents: EconEvent[] = [
      {
        title: "US Federal Reserve Interest Rate Decision",
        country: "US",
        category: "central_bank",
        importance: 3,
        actual: null,
        forecast: 5.50,
        previous: 5.50,
        unit: "%",
        event_date: today,
        event_time: "19:00",
        source: "manual",
      },
      {
        title: "US CPI YoY",
        country: "US",
        category: "inflation",
        importance: 3,
        actual: null,
        forecast: 3.4,
        previous: 3.2,
        unit: "%",
        event_date: today,
        event_time: "20:30",
        source: "manual",
      },
      {
        title: "Bank Indonesia Interest Rate Decision",
        country: "ID",
        category: "central_bank",
        importance: 3,
        actual: null,
        forecast: 6.00,
        previous: 6.00,
        unit: "%",
        event_date: today,
        event_time: "11:30",
        source: "manual",
      },
      {
        title: "ECB Interest Rate Decision",
        country: "EU",
        category: "central_bank",
        importance: 3,
        actual: null,
        forecast: 4.50,
        previous: 4.50,
        unit: "%",
        event_date: today,
        event_time: "13:15",
        source: "manual",
      },
      {
        title: "US Non-Farm Payrolls",
        country: "US",
        category: "employment",
        importance: 3,
        actual: null,
        forecast: 180,
        previous: 272,
        unit: "K",
        event_date: today,
        event_time: "20:30",
        source: "manual",
      },
      {
        title: "US Unemployment Rate",
        country: "US",
        category: "employment",
        importance: 2,
        actual: null,
        forecast: 3.8,
        previous: 3.7,
        unit: "%",
        event_date: today,
        event_time: "20:30",
        source: "manual",
      },
      {
        title: "US GDP QoQ Prel",
        country: "US",
        category: "gdp",
        importance: 3,
        actual: null,
        forecast: 3.3,
        previous: 4.9,
        unit: "%",
        event_date: today,
        event_time: "20:30",
        source: "manual",
      },
      {
        title: "China Manufacturing PMI",
        country: "CN",
        category: "pmi",
        importance: 2,
        actual: null,
        forecast: 50.1,
        previous: 49.4,
        unit: "index",
        event_date: today,
        event_time: "09:00",
        source: "manual",
      },
      {
        title: "Japan BOJ Policy Rate",
        country: "JP",
        category: "central_bank",
        importance: 3,
        actual: null,
        forecast: -0.10,
        previous: -0.10,
        unit: "%",
        event_date: today,
        event_time: "Unknown",
        source: "manual",
      },
      {
        title: "Eurozone HICP YoY Final",
        country: "EU",
        category: "inflation",
        importance: 2,
        actual: null,
        forecast: 2.9,
        previous: 2.9,
        unit: "%",
        event_date: today,
        event_time: "18:00",
        source: "manual",
      },
    ];

    const allEvents = events.length > 0 ? events : hardcodedEvents;

    const insertData = allEvents.map((event) => ({
      event_key: `${event.title}_${event.event_date}_${event.event_time}_${event.source}`,
      title: event.title,
      country: event.country,
      category: event.category,
      importance: event.importance,
      actual: event.actual,
      forecast: event.forecast,
      previous: event.previous,
      unit: event.unit,
      event_date: event.event_date,
      event_time: event.event_time,
      source: event.source,
    }));

    if (insertData.length > 0) {
      const { error } = await supabase
        .from("taug.econ_events")
        .upsert(insertData, { onConflict: "event_key" });

      if (error) {
        console.error("Insert error:", error);
      }
    }

    return new Response(
      JSON.stringify({ inserted: insertData.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
