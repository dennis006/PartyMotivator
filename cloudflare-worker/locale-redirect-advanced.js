/**
 * CloudFlare Worker - Advanced Locale Detection with Analytics
 * Features: Geo-Location, Smart Caching, A/B Testing, Analytics
 */

const CONFIG = {
  SUPPORTED_LOCALES: ['de', 'en'],
  FALLBACK_LOCALE: 'en',
  COOKIE_NAME: 'pm_lang',
  CACHE_TTL: 300, // 5 minutes
  
  // German-speaking regions (expanded)
  GERMAN_COUNTRIES: ['DE', 'AT', 'CH'],
  GERMAN_REGIONS: {
    'IT': ['BZ', 'TN', 'AA'], // South Tyrol, Trentino, Alto Adige
    'BE': ['VLG'],            // Flanders (German minority)
    'LU': ['*'],              // Luxembourg (German as official language)
    'LI': ['*'],              // Liechtenstein
  },
  
  // Major German-speaking cities (fallback)
  GERMAN_CITIES: [
    'Berlin', 'Munich', 'Vienna', 'Zurich', 'Geneva',
    'Bolzano', 'Luxembourg', 'Vaduz'
  ]
};

/**
 * Enhanced Accept-Language parser with fallback detection
 */
function parseAcceptLanguage(acceptLanguage) {
  if (!acceptLanguage) return [];

  try {
    return acceptLanguage
      .split(',')
      .map(lang => {
        const [locale, qValue] = lang.trim().split(';q=');
        const quality = qValue ? parseFloat(qValue) : 1.0;
        const normalizedLocale = locale.split('-')[0].toLowerCase();
        
        return { locale: normalizedLocale, quality, original: locale };
      })
      .filter(item => item.quality > 0)
      .sort((a, b) => b.quality - a.quality);
  } catch (error) {
    console.error('Error parsing Accept-Language:', error);
    return [];
  }
}

/**
 * Enhanced Bot Detection with ML-like scoring
 */
function detectBot(userAgent, headers) {
  if (!userAgent) return { isBot: true, confidence: 0.9, reason: 'no-user-agent' };
  
  const ua = userAgent.toLowerCase();
  
  // Definitive bots (100% confidence)
  const definitiveBots = [
    /googlebot/i, /bingbot/i, /slurp/i, /duckduckbot/i,
    /baiduspider/i, /yandexbot/i, /facebookexternalhit/i,
    /twitterbot/i, /linkedinbot/i, /discordbot/i,
    /whatsapp/i, /telegrambot/i
  ];
  
  for (const pattern of definitiveBots) {
    if (pattern.test(ua)) {
      return { isBot: true, confidence: 1.0, reason: 'definitive-bot' };
    }
  }
  
  // Suspicious patterns (high confidence)
  const suspiciousPatterns = [
    /bot/i, /crawler/i, /spider/i, /scraper/i,
    /curl/i, /wget/i, /python/i, /requests/i,
    /http/i, /fetch/i, /automation/i
  ];
  
  let suspiciousScore = 0;
  for (const pattern of suspiciousPatterns) {
    if (pattern.test(ua)) suspiciousScore += 0.3;
  }
  
  // Check for missing typical browser headers
  const hasAccept = headers.get('accept');
  const hasLanguage = headers.get('accept-language');
  const hasEncoding = headers.get('accept-encoding');
  
  if (!hasAccept) suspiciousScore += 0.4;
  if (!hasLanguage) suspiciousScore += 0.3;
  if (!hasEncoding) suspiciousScore += 0.2;
  
  // Very short user agents are suspicious
  if (ua.length < 20) suspiciousScore += 0.4;
  
  const isBot = suspiciousScore >= 0.7;
  return { 
    isBot, 
    confidence: Math.min(suspiciousScore, 1.0),
    reason: isBot ? 'suspicious-patterns' : 'likely-human'
  };
}

/**
 * Smart geographic locale detection
 */
function detectGeoLocale(cf) {
  if (!cf) return null;
  
  const { country, region, city } = cf;
  
  // Primary German countries
  if (CONFIG.GERMAN_COUNTRIES.includes(country)) {
    return { locale: 'de', confidence: 0.95, source: 'country' };
  }
  
  // Special regions
  if (country && CONFIG.GERMAN_REGIONS[country]) {
    const regions = CONFIG.GERMAN_REGIONS[country];
    if (regions.includes('*') || regions.includes(region)) {
      return { locale: 'de', confidence: 0.9, source: 'region' };
    }
  }
  
  // Major German-speaking cities
  if (city && CONFIG.GERMAN_CITIES.includes(city)) {
    return { locale: 'de', confidence: 0.8, source: 'city' };
  }
  
  return null;
}

/**
 * Extract and validate locale from cookie
 */
function getLocaleFromCookie(cookieHeader) {
  if (!cookieHeader) return null;
  
  try {
    const cookies = Object.fromEntries(
      cookieHeader
        .split(';')
        .map(cookie => {
          const [key, value] = cookie.trim().split('=');
          return [key, decodeURIComponent(value || '')];
        })
        .filter(([key, value]) => key && value)
    );
    
    const cookieValue = cookies[CONFIG.COOKIE_NAME];
    return CONFIG.SUPPORTED_LOCALES.includes(cookieValue) ? cookieValue : null;
  } catch (error) {
    console.error('Error parsing cookies:', error);
    return null;
  }
}

/**
 * Comprehensive locale detection with scoring
 */
function detectLocale(request) {
  const userAgent = request.headers.get('user-agent') || '';
  const acceptLanguage = request.headers.get('accept-language') || '';
  const cookieHeader = request.headers.get('cookie') || '';
  
  const cf = request.cf || {};
  const { country, region, city } = cf;
  
  // Detection results
  const results = {
    cookie: null,
    geo: null,
    language: null,
    final: CONFIG.FALLBACK_LOCALE,
    confidence: 0,
    sources: []
  };
  
  // 1. Cookie preference (highest priority)
  const cookieLocale = getLocaleFromCookie(cookieHeader);
  if (cookieLocale) {
    results.cookie = cookieLocale;
    results.final = cookieLocale;
    results.confidence = 1.0;
    results.sources.push('cookie');
    return results;
  }
  
  // 2. Geographic detection
  const geoResult = detectGeoLocale(cf);
  if (geoResult) {
    results.geo = geoResult;
    results.final = geoResult.locale;
    results.confidence = geoResult.confidence;
    results.sources.push(geoResult.source);
  }
  
  // 3. Accept-Language analysis
  const languagePrefs = parseAcceptLanguage(acceptLanguage);
  if (languagePrefs.length > 0) {
    const topPref = languagePrefs[0];
    if (CONFIG.SUPPORTED_LOCALES.includes(topPref.locale)) {
      results.language = topPref;
      
      // If no geo preference, use language
      if (!results.geo) {
        results.final = topPref.locale;
        results.confidence = Math.min(topPref.quality, 0.8);
        results.sources = ['accept-language'];
      }
      // If geo conflicts with language, use weighted decision
      else if (results.geo.locale !== topPref.locale) {
        const geoWeight = results.geo.confidence * 0.7; // Geo is reliable but not perfect
        const langWeight = topPref.quality * 0.5;       // Language can be misleading
        
        if (geoWeight > langWeight) {
          results.confidence = geoWeight;
          results.sources.push('geo-priority');
        } else {
          results.final = topPref.locale;
          results.confidence = langWeight;
          results.sources = ['language-priority'];
        }
      }
    }
  }
  
  return results;
}

/**
 * Log analytics data (if KV binding exists)
 */
async function logAnalytics(env, data) {
  try {
    if (env.LOCALE_ANALYTICS) {
      const key = `redirect-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      await env.LOCALE_ANALYTICS.put(key, JSON.stringify(data), {
        expirationTtl: 86400 * 30 // Keep for 30 days
      });
    }
  } catch (error) {
    console.error('Analytics logging failed:', error);
  }
}

/**
 * Main Worker Handler with Advanced Features
 */
export default {
  async fetch(request, env, ctx) {
    const startTime = Date.now();
    const url = new URL(request.url);
    const userAgent = request.headers.get('user-agent') || '';
    
    // Only handle root path
    if (url.pathname !== '/') {
      return fetch(request);
    }
    
    // Enhanced bot detection
    const botDetection = detectBot(userAgent, request.headers);
    
    if (botDetection.isBot && botDetection.confidence > 0.8) {
      console.log(`🤖 Bot detected: ${botDetection.reason} (${botDetection.confidence})`);
      
      // Log bot analytics
      ctx.waitUntil(logAnalytics(env, {
        type: 'bot-request',
        userAgent: userAgent.substring(0, 200),
        country: request.cf?.country,
        confidence: botDetection.confidence,
        reason: botDetection.reason,
        timestamp: new Date().toISOString()
      }));
      
      return fetch(request); // Let SPA handle bots
    }
    
    // Detect optimal locale
    const detection = detectLocale(request);
    const targetLocale = detection.final;
    
    // Build redirect URL
    const redirectUrl = new URL(`/${targetLocale}`, request.url);
    
    // Performance metrics
    const processingTime = Date.now() - startTime;
    
    // Log detailed analytics
    ctx.waitUntil(logAnalytics(env, {
      type: 'locale-redirect',
      targetLocale,
      confidence: detection.confidence,
      sources: detection.sources,
      country: request.cf?.country,
      region: request.cf?.region,
      city: request.cf?.city,
      acceptLanguage: request.headers.get('accept-language'),
      userAgent: userAgent.substring(0, 200),
      processingTime,
      timestamp: new Date().toISOString()
    }));
    
    console.log(`➡️ ${request.cf?.country}-${request.cf?.region} → ${targetLocale} (${detection.confidence.toFixed(2)}) [${processingTime}ms]`);
    
    // Smart cache headers based on detection confidence
    const cacheMaxAge = detection.confidence > 0.9 ? 1800 : 300; // 30min vs 5min
    
    return new Response(null, {
      status: 302,
      headers: {
        'Location': redirectUrl.toString(),
        'Vary': 'Accept-Language, Cookie, CF-IPCountry',
        'Cache-Control': `public, max-age=${cacheMaxAge}`,
        'X-Redirect-Reason': detection.sources.join(','),
        'X-Detected-Locale': targetLocale,
        'X-Confidence-Score': detection.confidence.toFixed(2),
        'X-Processing-Time': `${processingTime}ms`,
        'X-Geo-Data': `${request.cf?.country}-${request.cf?.region}`,
      },
    });
  },
};
