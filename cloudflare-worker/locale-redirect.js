/**
 * CloudFlare Worker for Intelligent Locale Detection
 * Handles automatic language detection with Geo-Location + Accept-Language
 */

// Configuration
const SUPPORTED_LOCALES = ['de', 'en'];
const FALLBACK_LOCALE = 'en';
const COOKIE_NAME = 'pm_lang';

// German-speaking countries/regions
const GERMAN_COUNTRIES = ['DE', 'AT', 'CH'];
const GERMAN_REGIONS = {
  'IT': ['BZ', 'TN'], // South Tyrol, Trentino
  'BE': ['VLG'], // Flanders (some German speakers)
};

/**
 * Parse Accept-Language header with quality values
 */
function parseAcceptLanguage(acceptLanguage) {
  if (!acceptLanguage) return [];

  return acceptLanguage
    .split(',')
    .map(lang => {
      const [locale, qValue] = lang.trim().split(';q=');
      const quality = qValue ? parseFloat(qValue) : 1.0;
      const normalizedLocale = locale.split('-')[0].toLowerCase();
      
      return { locale: normalizedLocale, quality };
    })
    .filter(item => item.quality > 0 && SUPPORTED_LOCALES.includes(item.locale))
    .sort((a, b) => b.quality - a.quality);
}

/**
 * Check if User-Agent indicates a bot/crawler
 */
function isBot(userAgent) {
  if (!userAgent) return false;
  
  const botPatterns = [
    /bot/i, /crawler/i, /spider/i, /google/i, /bing/i,
    /yandex/i, /baidu/i, /duckduckbot/i, /facebookexternalhit/i,
    /twitterbot/i, /linkedinbot/i, /whatsapp/i, /telegram/i,
    /curl/i, /wget/i, /python/i, /requests/i
  ];
  
  return botPatterns.some(pattern => pattern.test(userAgent));
}

/**
 * Extract locale from cookie
 */
function getLocaleFromCookie(cookieHeader) {
  if (!cookieHeader) return null;
  
  const cookies = cookieHeader
    .split(';')
    .reduce((acc, cookie) => {
      const [key, value] = cookie.trim().split('=');
      if (key && value) acc[key] = value;
      return acc;
    }, {});
  
  const cookieValue = cookies[COOKIE_NAME];
  return SUPPORTED_LOCALES.includes(cookieValue) ? cookieValue : null;
}

/**
 * Intelligent locale detection with geo-location priority
 */
function detectLocale(request) {
  const url = new URL(request.url);
  const userAgent = request.headers.get('user-agent') || '';
  const acceptLanguage = request.headers.get('accept-language') || '';
  const cookieHeader = request.headers.get('cookie') || '';
  
  // CloudFlare provides geo data
  const country = request.cf?.country;
  const region = request.cf?.region;
  const city = request.cf?.city;
  
  console.log(`🌍 Geo: ${country}-${region}, City: ${city}`);
  console.log(`🗣️ Lang: ${acceptLanguage}`);
  
  // 1. Check user preference cookie (highest priority)
  const cookieLocale = getLocaleFromCookie(cookieHeader);
  if (cookieLocale) {
    console.log(`🍪 Cookie preference: ${cookieLocale}`);
    return cookieLocale;
  }
  
  // 2. Geographic detection (very reliable)
  if (country) {
    // Direct German countries
    if (GERMAN_COUNTRIES.includes(country)) {
      console.log(`🇩🇪 German country detected: ${country}`);
      return 'de';
    }
    
    // Special regions with German speakers
    if (GERMAN_REGIONS[country]?.includes(region)) {
      console.log(`🗺️ German region detected: ${country}-${region}`);
      return 'de';
    }
  }
  
  // 3. Accept-Language header analysis
  const languagePrefs = parseAcceptLanguage(acceptLanguage);
  if (languagePrefs.length > 0) {
    const topChoice = languagePrefs[0];
    console.log(`🌐 Browser language: ${topChoice.locale} (q=${topChoice.quality})`);
    return topChoice.locale;
  }
  
  // 4. Fallback
  console.log(`🔄 Using fallback: ${FALLBACK_LOCALE}`);
  return FALLBACK_LOCALE;
}

/**
 * Main Worker handler
 */
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const userAgent = request.headers.get('user-agent') || '';
    
    console.log(`📍 Request: ${request.method} ${url.pathname}`);
    
    // Only handle root path
    if (url.pathname !== '/') {
      return fetch(request); // Pass through
    }
    
    // Don't redirect bots (SEO protection)
    if (isBot(userAgent)) {
      console.log(`🤖 Bot detected: ${userAgent.substring(0, 50)}...`);
      return fetch(request); // Let SPA handle bots
    }
    
    // Detect optimal locale
    const targetLocale = detectLocale(request);
    
    // Build redirect URL
    const redirectUrl = new URL(`/${targetLocale}`, request.url);
    
    console.log(`➡️ Redirecting to: ${redirectUrl.toString()}`);
    
    // Perform 302 redirect
    return new Response(null, {
      status: 302,
      headers: {
        'Location': redirectUrl.toString(),
        'Vary': 'Accept-Language, Cookie, CF-IPCountry',
        'Cache-Control': 'public, max-age=300', // 5min cache for performance
        'X-Redirect-Reason': `geo-${request.cf?.country || 'unknown'}`,
        'X-Detected-Locale': targetLocale,
      },
    });
  },
};
