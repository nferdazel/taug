import "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://taug.vercel.app",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface FeedItem {
  title: string;
  link: string;
  description: string;
  pubDate: string;
  source: string;
  agency: string;
  country: string;
}

interface FeedConfig {
  url: string;
  source: string;
  agency: string;
  country: string;
}

const policyFeeds: FeedConfig[] = [
  {
    url: "https://www.federalreserve.gov/feeds/press_all.xml",
    source: "Federal Reserve Press Releases",
    agency: "Federal Reserve",
    country: "US",
  },
  {
    url: "https://www.sec.gov/news/pressreleases.rss",
    source: "SEC Press Releases",
    agency: "SEC",
    country: "US",
  },
];

function stripHtml(input: string): string {
  return input.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
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

function extractTagValue(xml: string, tag: string): string {
  const pattern =
    new RegExp(
      `<${tag}>(?:<!\\[CDATA\\[)?([\\s\\S]*?)(?:\\]\\]>)?<\\/${tag}>`,
      "i",
    );
  return xml.match(pattern)?.[1]?.trim() ?? "";
}

function parseRss(xml: string, feed: FeedConfig): FeedItem[] {
  if (!xml.includes("<item>")) {
    return [];
  }

  const items: FeedItem[] = [];
  const itemRegex = /<item>([\s\S]*?)<\/item>/g;
  let match: RegExpExecArray | null;

  while ((match = itemRegex.exec(xml)) !== null) {
    const itemXml = match[1];
    const title = extractTagValue(itemXml, "title");
    const link = extractTagValue(itemXml, "link");
    const description = extractTagValue(itemXml, "description");
    const pubDate = extractTagValue(itemXml, "pubDate");

    if (title && link) {
      items.push({
        title: stripHtml(title),
        link: canonicalizeUrl(link),
        description: stripHtml(description).slice(0, 500),
        pubDate: pubDate
          ? new Date(pubDate).toISOString()
          : new Date().toISOString(),
        source: feed.source,
        agency: feed.agency,
        country: feed.country,
      });
    }
  }

  return items;
}

function determineCategory(text: string): string {
  const lower = text.toLowerCase();
  if (lower.match(/sanction|enforcement|penalt|settlement|fraud|compliance/)) {
    return "enforcement";
  }
  if (lower.match(/interest rate|monetary|fomc|liquidity|banking/)) {
    return "monetary_policy";
  }
  if (lower.match(/executive order|proclamation|statement|briefing/)) {
    return "executive_action";
  }
  if (lower.match(/treasury|tax|debt|bond|auction|fiscal/)) {
    return "fiscal_policy";
  }
  if (lower.match(/securities|disclosure|filing|investor|market/)) {
    return "market_regulation";
  }
  return "policy";
}

function determineImportance(text: string): number {
  const lower = text.toLowerCase();
  if (
    lower.match(
      /emergency|executive order|sanction|fomc|rate decision|enforcement action/,
    )
  ) {
    return 3;
  }
  if (lower.match(/statement|guidance|proposal|rule|treasury|sec/)) {
    return 2;
  }
  return 1;
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

    const supabase = createClient(supabaseUrl, supabaseKey, {
      db: { schema: "taug" },
    });

    const allItems: FeedItem[] = [];
    const results = await Promise.all(
      policyFeeds.map(async (feed) => {
        try {
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), 10000);
          const response = await fetch(feed.url, {
            signal: controller.signal,
            headers: { "User-Agent": "Taug/1.0" },
          });
          clearTimeout(timeout);

          if (!response.ok) {
            return <FeedItem[]>[];
          }

          const xml = await response.text();
          return parseRss(xml, feed);
        } catch {
          return <FeedItem[]>[];
        }
      }),
    );

    for (const items of results) {
      allItems.push(...items);
    }

    allItems.sort((a, b) =>
      new Date(b.pubDate).getTime() - new Date(a.pubDate).getTime()
    );

    const uniqueItems = new Map<string, FeedItem>();
    for (const item of allItems) {
      uniqueItems.set(item.link, item);
    }

    const insertData = Array.from(uniqueItems.values()).slice(0, 100).map((
      item,
    ) => {
      const combinedText = `${item.title} ${item.description}`;
      const category = determineCategory(combinedText);
      return {
        external_id: item.link,
        title: item.title,
        summary: item.description,
        url: item.link,
        source: item.source,
        source_label: item.source,
        country: item.country,
        agency: item.agency,
        category,
        importance: determineImportance(combinedText),
        published_at: item.pubDate,
        metadata: {
          tags: [category],
        },
        source_url: item.link,
        latency_class: "syndicated",
        is_official: true,
        is_synthetic: false,
        fetched_at: new Date().toISOString(),
        as_of: item.pubDate,
      };
    });

    if (insertData.length > 0) {
      const { error } = await supabase
        .from("policy_events")
        .upsert(insertData, { onConflict: "external_id" });

      if (error) {
        throw error;
      }
    }

    return new Response(
      JSON.stringify({ inserted: insertData.length }),
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
