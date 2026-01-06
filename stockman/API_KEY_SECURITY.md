# API Key Security Guide

## ⚠️ URGENT: Your API keys have been exposed to GitHub!

### Immediate Actions Required:

#### 1. **Rotate/Regenerate ALL Exposed Keys** (Do this NOW!)

**Google Maps API Key:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Find your API key: `AIzaSyCRBSCPIFVUFlXPgBWBBLRPJLLxPf8ZHLE`
3. **Delete it** or **Regenerate** it
4. Create a new API key with proper restrictions:
   - **Application restrictions**: Android apps + iOS apps
   - **API restrictions**: Maps SDK for Android, Maps SDK for iOS, Geocoding API
   - **Add your package name**: `com.example.stockman` (or your actual package)
   - **Add your SHA-1 certificate fingerprint** for Android

**Supabase Keys:**
- **Good news**: Supabase anon key is meant to be public (it's safe)
- **BUT**: Check your Row Level Security (RLS) policies are enabled
- Go to Supabase Dashboard → Authentication → Policies
- Ensure all tables have proper RLS rules

**Google OAuth Client IDs:**
- These are also meant to be public (safe for mobile apps)
- No action needed unless you suspect abuse

#### 2. **Remove Keys from Git History**

Your keys are still in GitHub history. Run these commands:

```bash
# Install BFG Repo Cleaner
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

# Create a backup first!
cd ..
git clone --mirror https://github.com/GerritSt/StockMan.git StockMan-backup

# Remove sensitive data
cd StockMan
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/src/config/supabase_config.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Force push to GitHub
git push origin --force --all
```

**OR use GitHub's built-in tool:**
1. Go to your repo settings
2. Security → Secret scanning → Review alerts
3. GitHub may have already detected the keys
4. Follow their removal instructions

#### 3. **Secure Your Keys Going Forward**

All keys are now in `.env` file which is gitignored. Run your app with:

```bash
flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL \
            --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
            --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID \
            --dart-define=GOOGLE_ANDROID_CLIENT_ID=$GOOGLE_ANDROID_CLIENT_ID
```

Or create a launch script:

```bash
# Create run.sh
source .env
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID \
  --dart-define=GOOGLE_ANDROID_CLIENT_ID=$GOOGLE_ANDROID_CLIENT_ID
```

### What I've Done:

✅ Created `.env` file with your current keys (gitignored)
✅ Created `.env.example` as a template (safe to commit)
✅ Updated `.gitignore` to prevent committing `.env`
✅ Removed hardcoded keys from `supabase_config.dart`
✅ Keys now load from `--dart-define` environment variables

### Files Changed:

1. **[.env](.env)** - Contains actual keys (NEVER COMMIT!)
2. **[.env.example](.env.example)** - Template (safe to commit)
3. **[.gitignore](.gitignore)** - Added `.env` to ignore list
4. **[supabase_config.dart](lib/src/config/supabase_config.dart)** - Removed hardcoded keys

### Next Steps:

1. ✅ **Verify .env is gitignored:**
   ```bash
   git status
   # .env should NOT appear in the list
   ```

2. ✅ **Commit the security changes:**
   ```bash
   git add .gitignore .env.example lib/src/config/supabase_config.dart
   git commit -m "Security: Remove hardcoded API keys, use environment variables"
   git push
   ```

3. ⚠️ **Regenerate Google Maps API key** (most critical!)

4. ✅ **Test app with environment variables:**
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://obqkmorzxfmecarodsnx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9icWttb3J6eGZtZWNhcm9kc254Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjQ3OTgsImV4cCI6MjA3NjEwMDc5OH0.V1dATtgSEEV64rYn2GI94AvKIbdAEIbouRUGV2YYFWA
   ```

### Security Best Practices:

- ✅ Never commit `.env` files
- ✅ Always use `.env.example` as template
- ✅ Use `--dart-define` for Flutter environment variables
- ✅ Enable Row Level Security (RLS) in Supabase
- ✅ Restrict API keys to specific apps/domains
- ✅ Rotate keys regularly
- ✅ Monitor API usage for suspicious activity

### Why Each Key Matters:

**Google Maps API Key (HIGH RISK):**
- Can be abused for unlimited Maps API calls
- **Could cost you money!**
- **ACTION REQUIRED: Regenerate immediately**

**Supabase Anon Key (LOW RISK):**
- Designed to be public
- Safe if RLS policies are properly configured
- Check your database policies

**Google OAuth IDs (LOW RISK):**
- Designed to be public for mobile apps
- No financial risk
- Users still need to authenticate

---

**PRIORITY:** Regenerate your Google Maps API key ASAP! 🔥
