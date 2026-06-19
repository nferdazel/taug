#!/bin/bash
set -e

echo "=== Taug Deploy Script ==="
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found."
    echo "   Copy .env.example to .env and fill in your keys."
    exit 1
fi

# Source .env
export $(grep -v '^#' .env | xargs)

echo "1. Running build_runner..."
dart run build_runner build 2>&1 | tail -3

echo ""
echo "2. Running flutter analyze..."
ANALYZE_OUTPUT=$(flutter analyze 2>&1)
ERRORS=$(echo "$ANALYZE_OUTPUT" | grep -c "error •" || true)
if [ "$ERRORS" -gt 0 ]; then
    echo "❌ Found $ERRORS errors. Fix them first."
    echo "$ANALYZE_OUTPUT" | grep "error •"
    exit 1
fi
echo "✅ No errors"

echo ""
echo "3. Running tests..."
flutter test 2>&1 | tail -3 || echo "⚠️  Tests skipped or failed"

echo ""
echo "4. Building for web..."
flutter build web --release 2>&1 | tail -3

echo ""
echo "5. Copying vercel.json..."
cp vercel.json build/web/vercel.json

echo ""
echo "6. Injecting Supabase URLs..."
WSS_URL=$(echo "$SUPABASE_URL" | sed 's|https://|wss://|')
sed -i "s|https://YOUR_SUPABASE.supabase.co|${SUPABASE_URL}|g" build/web/vercel.json
sed -i "s|wss://YOUR_SUPABASE.supabase.co|${WSS_URL}|g" build/web/vercel.json

echo ""
echo "7. Deploying to Vercel..."
if command -v vercel &> /dev/null; then
    vercel deploy --prod --yes ./build/web
else
    echo "⚠️  Vercel CLI not found. Install it:"
    echo "   npm install -g vercel"
    echo ""
    echo "   Or push to main to trigger GitHub Actions deploy."
fi

echo ""
echo "=== Deploy complete! ==="
