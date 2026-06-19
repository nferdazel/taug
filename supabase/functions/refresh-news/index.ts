import "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface RssItem {
  title: string;
  link: string;
  description: string;
  pubDate: string;
  source: string;
  sourceUrl: string;
  isOfficial: boolean;
}

interface FeedConfig {
  url: string;
  source: string;
  sourceUrl: string;
  isOfficial: boolean;
}

function stripHtml(text: string): string {
  return text.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
}

function canonicalizeUrl(url: string): string {
  try {
    const normalized = new URL(url.trim());
    normalized.hash = "";
    if (normalized.pathname.endsWith("/")) {
      normalized.pathname = normalized.pathname.slice(0, -1);
    }
    return normalized.toString();
  } catch {
    return url.trim();
  }
}

function parseRss(xml: string, feed: FeedConfig): RssItem[] {
  const items: RssItem[] = [];
  const itemRegex = /<item>([\s\S]*?)<\/item>/g;
  let match;

  while ((match = itemRegex.exec(xml)) !== null) {
    const itemXml = match[1];
    const title = itemXml.match(/<title><!\[CDATA\[(.*?)\]\]><\/title>/)?.[1]
      || itemXml.match(/<title>(.*?)<\/title>/)?.[1]
      || "";
    const link = itemXml.match(/<link>(.*?)<\/link>/)?.[1] || "";
    const description = itemXml.match(/<description><!\[CDATA\[(.*?)\]\]><\/description>/)?.[1]
      || itemXml.match(/<description>(.*?)<\/description>/)?.[1]
      || "";
    const pubDate = itemXml.match(/<pubDate>(.*?)<\/pubDate>/)?.[1] || "";

    if (title && link) {
      items.push({
        title: stripHtml(title),
        link: canonicalizeUrl(link),
        description: stripHtml(description).slice(0, 500),
        pubDate: pubDate ? new Date(pubDate).toISOString() : new Date().toISOString(),
        source: feed.source,
        sourceUrl: feed.sourceUrl,
        isOfficial: feed.isOfficial,
      });
    }
  }

  return items;
}

const RSS_FEEDS: FeedConfig[] = [
  {
    url: "https://www.cnbc.com/id/15839135/device/rss/rss.html",
    source: "CNBC Markets",
    sourceUrl: "https://www.cnbc.com/markets/",
    isOfficial: false,
  },
  {
    url: "https://www.cnbc.com/id/100003114/device/rss/rss.html",
    source: "CNBC Top News",
    sourceUrl: "https://www.cnbc.com/",
    isOfficial: false,
  },
  {
    url: "https://feeds.marketwatch.com/marketwatch/topstories/",
    source: "MarketWatch",
    sourceUrl: "https://www.marketwatch.com/",
    isOfficial: false,
  },
  {
    url: "https://feeds.marketwatch.com/marketwatch/marketpulse/",
    source: "MarketWatch Pulse",
    sourceUrl: "https://www.marketwatch.com/marketpulse",
    isOfficial: false,
  },
  {
    url: "https://www.reuters.com/arc/outboundfeeds/rss/v3/all/markets/",
    source: "Reuters Markets",
    sourceUrl: "https://www.reuters.com/markets/",
    isOfficial: false,
  },
  {
    url: "https://www.antaranews.com/rss/ekonomi",
    source: "Antara Economy",
    sourceUrl: "https://www.antaranews.com/ekonomi",
    isOfficial: false,
  },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseKey);

    const allItems: RssItem[] = [];

    const fetchPromises = RSS_FEEDS.map(async (feed) => {
      try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 10000);

        const response = await fetch(feed.url, {
          signal: controller.signal,
          headers: { "User-Agent": "Taug/1.0" },
        });
        clearTimeout(timeout);

        if (response.ok) {
          const xml = await response.text();
          return parseRss(xml, feed);
        }
      } catch {
        return [];
      }
      return [];
    });

    const results = await Promise.all(fetchPromises);
    for (const items of results) {
      allItems.push(...items);
    }

    allItems.sort((a, b) =>
      new Date(b.pubDate).getTime() - new Date(a.pubDate).getTime()
    );

    const uniqueItems = new Map<string, RssItem>();
    for (const item of allItems) {
      uniqueItems.set(item.link, item);
    }

    const limitedItems = Array.from(uniqueItems.values()).slice(0, 100);

    const insertData = limitedItems.map((item) => {
      const combinedText = `${item.title} ${item.description}`;
      return {
        external_id: item.link,
        title: item.title,
        summary: item.description,
        url: item.link,
        source: item.source,
        source_label: item.source,
        published_at: item.pubDate,
        categories: determineCategories(combinedText),
        is_breaking: isBreaking(item.title),
        source_url: item.sourceUrl,
        latency_class: "syndicated",
        is_official: item.isOfficial,
        is_synthetic: false,
        fetched_at: new Date().toISOString(),
        as_of: item.pubDate,
        metadata: {
          importance: determineImportance(combinedText),
          policy_relevant: isPolicyRelevant(combinedText),
        },
      };
    });

    if (insertData.length > 0) {
      const { error } = await supabase
        .from("taug.news_articles")
        .upsert(insertData, { onConflict: "external_id" });

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

function determineCategories(text: string): string[] {
  const lower = text.toLowerCase();
  const categories: string[] = [];

  if (lower.match(/fed|interest rate|monetary|central bank|boe|ecb|bi rate|rate cut|rate hike/)) {
    categories.push("central_bank");
  }
  if (lower.match(/inflation|cpi|ppi|deflation|price index/)) {
    categories.push("inflation");
  }
  if (lower.match(/gdp|economic growth|recession|contraction|expansion/)) {
    categories.push("economy");
  }
  if (lower.match(/war|conflict|sanction|geopolit|military|attack|missile|invasion/)) {
    categories.push("geopolitics");
  }
  if (lower.match(/president|white house|treasury|sec|congress|senate|executive order|regulator|policy/)) {
    categories.push("policy");
  }
  if (lower.match(/earthquake|tsunami|typhoon|hurricane|flood|disaster|volcano/)) {
    categories.push("disaster");
  }
  if (lower.match(/earnings|revenue|profit|loss|quarterly|annual report/)) {
    categories.push("earnings");
  }
  if (lower.match(/ipo|listing|delisting|merger|acquisition|m&a|buyout/)) {
    categories.push("corporate");
  }
  if (lower.match(/oil|gold|silver|copper|commodity|crude|precious metal/)) {
    categories.push("commodities");
  }
  if (lower.match(/bitcoin|crypto|ethereum|blockchain|token/)) {
    categories.push("crypto");
  }
  if (lower.match(/stock|equity|share|index|s&p|dow|nasdaq|nikkei|idx|Composite/)) {
    categories.push("markets");
  }
  if (lower.match(/export|import|trade balance|tariff|trade war/)) {
    categories.push("trade");
  }
  if (lower.match(/employment|jobs|unemployment|payroll|labor|non-farm/)) {
    categories.push("employment");
  }

  return categories.length > 0 ? categories : ["general"];
}

function isBreaking(title: string): boolean {
  const lower = title.toLowerCase();
  return lower.match(/breaking|urgent|alert|flash|just in|developing/) !== null;
}

function determineImportance(text: string): number {
  const lower = text.toLowerCase();
  if (lower.match(/war|sanction|fed|ecb|boe|treasury|white house|sec|executive order|rate decision/)) {
    return 3;
  }
  if (lower.match(/inflation|jobs|payroll|earnings|congress|senate|policy|regulation/)) {
    return 2;
  }
  return 1;
}

function isPolicyRelevant(text: string): boolean {
  const lower = text.toLowerCase();
  return lower.match(/white house|treasury|sec|congress|senate|executive order|sanction|regulation|policy/) !== null;
}
