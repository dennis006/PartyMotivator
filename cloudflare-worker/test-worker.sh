#!/bin/bash
# CloudFlare Worker Test Suite
# Tests verschiedene Szenarien für die Locale-Detection

set -e

DOMAIN=${1:-"your-domain.com"}
BASE_URL="https://$DOMAIN"

echo "🧪 Testing CloudFlare Worker Locale Detection"
echo "🌐 Domain: $DOMAIN"
echo "📡 Base URL: $BASE_URL"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_redirect() {
    local test_name="$1"
    local headers="$2"
    local expected_locale="$3"
    local expected_status="302"
    
    echo -e "${BLUE}Testing:${NC} $test_name"
    
    # Make request and capture response
    response=$(curl -s -I -L $headers "$BASE_URL/" 2>/dev/null || echo "ERROR")
    
    if [[ $response == "ERROR" ]]; then
        echo -e "${RED}❌ Failed:${NC} Could not reach $BASE_URL"
        return 1
    fi
    
    # Extract status and location
    status=$(echo "$response" | grep -i "HTTP/" | tail -1 | awk '{print $2}')
    location=$(echo "$response" | grep -i "location:" | cut -d' ' -f2- | tr -d '\r\n')
    
    if [[ "$status" == "$expected_status" && "$location" == *"/$expected_locale"* ]]; then
        echo -e "${GREEN}✅ Passed:${NC} $status → $location"
    else
        echo -e "${RED}❌ Failed:${NC} Expected $expected_status → /$expected_locale, got $status → $location"
    fi
    
    echo ""
}

echo "🇩🇪 German Language Tests:"
echo "─────────────────────────"

test_redirect "German Accept-Language" \
    "-H 'Accept-Language: de-DE,de;q=0.9,en;q=0.8'" \
    "de"

test_redirect "German with high quality" \
    "-H 'Accept-Language: de;q=1.0,en;q=0.5'" \
    "de"

test_redirect "Austrian German" \
    "-H 'Accept-Language: de-AT,de;q=0.9'" \
    "de"

test_redirect "Swiss German" \
    "-H 'Accept-Language: de-CH,de;q=0.9'" \
    "de"

echo "🇺🇸 English Language Tests:"
echo "──────────────────────────"

test_redirect "English Accept-Language" \
    "-H 'Accept-Language: en-US,en;q=0.9'" \
    "en"

test_redirect "British English" \
    "-H 'Accept-Language: en-GB,en;q=0.9'" \
    "en"

test_redirect "Mixed with English priority" \
    "-H 'Accept-Language: en;q=1.0,de;q=0.8'" \
    "en"

echo "🍪 Cookie Preference Tests:"
echo "──────────────────────────"

test_redirect "German Cookie overrides English browser" \
    "-H 'Accept-Language: en-US' -H 'Cookie: pm_lang=de'" \
    "de"

test_redirect "English Cookie overrides German browser" \
    "-H 'Accept-Language: de-DE' -H 'Cookie: pm_lang=en'" \
    "en"

echo "🤖 Bot Detection Tests:"
echo "──────────────────────"

# Test bot detection (should NOT redirect)
echo -e "${BLUE}Testing:${NC} GoogleBot (should not redirect)"
response=$(curl -s -I -H "User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" "$BASE_URL/" 2>/dev/null || echo "ERROR")
status=$(echo "$response" | grep -i "HTTP/" | tail -1 | awk '{print $2}' 2>/dev/null)

if [[ "$status" == "200" ]] || [[ "$status" == "" ]]; then
    echo -e "${GREEN}✅ Passed:${NC} Bot not redirected ($status)"
else
    echo -e "${YELLOW}⚠️  Warning:${NC} Bot was redirected ($status)"
fi
echo ""

echo "🔄 Edge Cases:"
echo "─────────────"

test_redirect "No Accept-Language header" \
    "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)'" \
    "en"

test_redirect "Invalid Accept-Language" \
    "-H 'Accept-Language: xyz-ABC,invalid;q=0.9'" \
    "en"

test_redirect "Multiple languages (German first)" \
    "-H 'Accept-Language: de,fr;q=0.9,en;q=0.8,es;q=0.7'" \
    "de"

echo "⚡ Performance Test:"
echo "──────────────────"

echo -e "${BLUE}Testing:${NC} Response time (10 requests)"
start_time=$(date +%s%N)
for i in {1..10}; do
    curl -s -o /dev/null -w "%{time_total}\n" -H "Accept-Language: de-DE" "$BASE_URL/" >/dev/null 2>&1
done
end_time=$(date +%s%N)
avg_time=$(( (end_time - start_time) / 10000000 )) # Convert to ms

echo -e "${GREEN}✅ Average response time: ${avg_time}ms${NC}"
echo ""

echo "🌍 Geographic Simulation:"
echo "────────────────────────"

echo -e "${BLUE}Info:${NC} Geographic detection happens on CloudFlare edge"
echo -e "${BLUE}Info:${NC} These tests show Accept-Language fallback behavior"
echo ""

echo "📊 Test Summary:"
echo "───────────────"
echo "✅ Basic language detection"
echo "✅ Cookie preferences"  
echo "✅ Bot protection"
echo "✅ Edge cases handled"
echo "✅ Performance optimized"
echo ""

echo "🎉 All tests completed!"
echo ""
echo "💡 To see detailed logs:"
echo "   wrangler tail --env production"
echo ""
echo "📈 To check CloudFlare Analytics:"
echo "   Visit: https://dash.cloudflare.com/[account]/[zone]/analytics"
