#!/bin/bash
set -e

echo "=== Taug Edge Functions Setup ==="
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Install it first:"
    echo "   brew install supabase/tap/supabase"
    exit 1
fi

# Check if linked to project
echo "Checking Supabase project link..."
if [ ! -f "supabase/.temp/project-ref" ]; then
    echo "❌ Not linked to a Supabase project."
    echo "   Run: supabase link --project-ref uikxnfcthytodkaupnmm"
    exit 1
fi

echo "✅ Linked to project: $(cat supabase/.temp/project-ref)"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found."
    exit 1
fi

# Load .env
source .env

# Set secrets
echo "Setting Edge Function secrets..."
if [ -z "$TWELVE_DATA_API_KEY" ] || [ "$TWELVE_DATA_API_KEY" = "YOUR_TWELVE_DATA_API_KEY" ]; then
    echo "❌ TWELVE_DATA_API_KEY not set in .env"
    exit 1
fi

supabase secrets set TWELVE_DATA_API_KEY="$TWELVE_DATA_API_KEY"

echo "✅ Secrets configured"
echo ""

# Deploy functions
echo "Deploying Edge Functions..."

echo "  → Deploying get-price..."
supabase functions deploy get-price --no-verify-jwt

echo "  → Deploying get-chart-data..."
supabase functions deploy get-chart-data --no-verify-jwt

echo "  → Deploying search-symbols..."
supabase functions deploy search-symbols --no-verify-jwt

echo "  → Deploying refresh-news..."
supabase functions deploy refresh-news --no-verify-jwt

echo "  → Deploying refresh-calendar..."
supabase functions deploy refresh-calendar --no-verify-jwt

echo ""
echo "=== All Edge Functions deployed! ==="
echo ""
echo "Test endpoints:"
echo "  https://uikxnfcthytodkaupnmm.supabase.co/functions/v1/get-price"
echo "  https://uikxnfcthytodkaupnmm.supabase.co/functions/v1/get-chart-data"
echo "  https://uikxnfcthytodkaupnmm.supabase.co/functions/v1/search-symbols"
echo "  https://uikxnfcthytodkaupnmm.supabase.co/functions/v1/refresh-news"
echo "  https://uikxnfcthytodkaupnmm.supabase.co/functions/v1/refresh-calendar"
echo ""
echo "Don't forget to set Supabase schema 'taug' as exposed in Dashboard → Settings → API"
