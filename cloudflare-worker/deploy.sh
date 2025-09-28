#!/bin/bash
# CloudFlare Worker Deployment Script für PartyMotivator
# 
# Usage: ./deploy.sh [environment]
# Environment: development, staging, production (default)

set -e

ENVIRONMENT=${1:-production}
WORKER_NAME="partymotivator-locale-redirect"

echo "🚀 Deploying CloudFlare Worker..."
echo "📦 Environment: $ENVIRONMENT"
echo "🏷️  Worker Name: $WORKER_NAME"

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found. Installing..."
    npm install -g wrangler
fi

# Check if user is logged in
echo "🔐 Checking CloudFlare authentication..."
if ! wrangler whoami &> /dev/null; then
    echo "❌ Not logged in. Please run: wrangler auth login"
    exit 1
fi

# Validate configuration
echo "✅ Validating wrangler.toml..."
if [ ! -f "wrangler.toml" ]; then
    echo "❌ wrangler.toml not found!"
    exit 1
fi

# Check if account_id and zone_id are configured
if grep -q 'account_id = ""' wrangler.toml; then
    echo "❌ Please set your account_id in wrangler.toml"
    echo "💡 Find it with: wrangler whoami"
    exit 1
fi

if grep -q 'zone_id = ""' wrangler.toml; then
    echo "❌ Please set your zone_id in wrangler.toml"
    echo "💡 Find it with: wrangler zone list"
    exit 1
fi

# Deploy the worker
echo "🚀 Deploying to CloudFlare..."

if [ "$ENVIRONMENT" = "development" ]; then
    echo "🧪 Development deployment (no custom domain)"
    wrangler deploy --env development
else
    echo "🌍 Production deployment with custom domain"
    wrangler deploy --env production
fi

# Show deployment status
echo "✅ Deployment complete!"
echo ""

# Get worker info
echo "📊 Worker Information:"
wrangler whoami
echo ""

# Show live logs option
echo "📈 To monitor live logs:"
echo "   wrangler tail --env $ENVIRONMENT"
echo ""

# Show worker URL
if [ "$ENVIRONMENT" = "production" ]; then
    echo "🌐 Your worker is now active on:"
    echo "   https://your-domain.com/"
else
    SUBDOMAIN=$(wrangler subdomain 2>/dev/null | grep -o '[a-z0-9\-]*\.workers\.dev' || echo "your-subdomain.workers.dev")
    echo "🧪 Development URL:"
    echo "   https://$WORKER_NAME.$SUBDOMAIN"
fi

echo ""
echo "🎉 CloudFlare Worker successfully deployed!"
echo ""
echo "Next steps:"
echo "1. Test the redirect: curl -H 'Accept-Language: de' https://your-domain.com/"
echo "2. Monitor with: wrangler tail --env $ENVIRONMENT"
echo "3. Check analytics in CloudFlare Dashboard"
