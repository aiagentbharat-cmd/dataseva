# DataSeva — Supabase Setup Guide
## 3 Steps to Go Live (Free)

---

## STEP 1 — Create Your Supabase Project (5 minutes)

1. Go to **https://supabase.com** → Sign up (free)
2. Click **"New Project"**
3. Project name: `dataseva`
4. Region: **Southeast Asia (Singapore)** — closest to India
5. Set a strong database password → **Save it somewhere**
6. Click **Create Project** → wait ~2 minutes

---

## STEP 2 — Run the Database Schema

1. In your Supabase project → Click **SQL Editor** (left sidebar)
2. Click **New Query**
3. Open the file `supabase_schema.sql` from this package
4. **Paste the entire contents** into the editor
5. Click **Run** (green button)
6. You should see: *"Success. No rows returned"*

That creates all 6 tables, indexes, RLS policies, and views.

---

## STEP 3 — Get Your API Keys

1. In Supabase → **Settings** (gear icon) → **API**
2. Copy these two values:

```
Project URL:    https://xxxxxxxxxxxx.supabase.co
anon/public:    eyJhbGciOiJIUzI1NiIs...   (for frontend)
service_role:   eyJhbGciOiJIUzI1NiIs...   (for admin panel ONLY)
```

**⚠️ IMPORTANT:**
- `anon` key → use in `index.html` (public-facing)
- `service_role` key → use ONLY in `admin.html` (bypasses all security)
- Never put `service_role` in a public website in production

---

## STEP 4 — Plug Keys into the Files

### In `index.html` (around line 450):
```javascript
const SUPABASE_URL = 'https://xxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIs...your-anon-key...';
```

### In `admin.html` (around line 280):
```javascript
const SUPABASE_URL = 'https://xxxxxxxxxxxx.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIs...your-service-role-key...';
```

---

## STEP 5 — Set Up Admin Login

1. In Supabase → **Authentication** → **Users** → **Invite User**
2. Enter your email → Send invite
3. Click the link in your email → set a password
4. In admin.html, update the login logic to use Supabase Auth:

```javascript
// Replace the demo login with:
const { data, error } = await sb.auth.signInWithPassword({
  email: email,
  password: pass
});
if (error) { /* show error */ }
else { /* proceed to dashboard */ }
```

---

## STEP 6 — Host the Files (Free Options)

### Option A: Netlify (Easiest — 5 minutes)
1. Go to **https://netlify.com** → Sign up free
2. Drag and drop your `dataseva/` folder onto the Netlify dashboard
3. You get a live URL like `https://dataseva-abc123.netlify.app`
4. Custom domain: buy `dataseva.in` (~₹800/year) → connect in Netlify

### Option B: Vercel
1. **https://vercel.com** → Import project from GitHub
2. Deploy in 2 clicks

### Option C: GitHub Pages (Free)
1. Create a GitHub repo → upload files
2. Settings → Pages → Deploy from main branch

---

## CAPACITY & COST BREAKDOWN

| Tier | Collectors | Companies | Cost |
|------|-----------|-----------|------|
| **Supabase Free** | 100,000+ | 10,000+ | **₹0/month** |
| Supabase Pro | Unlimited | Unlimited | ~₹2,100/month |
| Netlify Free hosting | — | — | **₹0/month** |
| Custom domain (.in) | — | — | ~₹800/year |

**Your total cost to launch: ₹0** (₹800/year if you want a custom domain)

### Why Free Tier Handles Your Scale:
- 100,000 collector profiles × 3KB avg = ~300MB → fits in 500MB free
- 10,000 company profiles × 2KB avg = ~20MB → fits easily
- Supabase free tier: 500MB database, 1GB file storage, 50,000 auth users/month

---

## ADMIN PANEL FEATURES

| Feature | How |
|---------|-----|
| Approve collector | Click ✅ in table or open profile → Approve |
| Reject collector | Open profile → add rejection note → Reject |
| Reject without note | ❌ Blocked — note is mandatory for rejections |
| Verify GST company | Mark GST Verified toggle → Approve |
| Suspend company | Reject with "Suspended: reason" note |
| Audit trail | Every approve/reject is logged with timestamp + admin email |
| Search | Type in search box — filters live across all columns |
| Filter by status | Pending / Approved / Rejected / Paused buttons |

---

## MULTILINGUAL SUPPORT

The frontend supports 12 languages switchable from the top nav:

| Language | Code | Coverage |
|----------|------|---------|
| English | en | 100% |
| Hindi हिन्दी | hi | 100% |
| Tamil தமிழ் | ta | Core UI |
| Telugu తెలుగు | te | Core UI |
| Kannada ಕನ್ನಡ | kn | Core UI |
| Malayalam മലയാളം | ml | Core UI |
| Marathi मराठी | mr | Core UI |
| Bengali বাংলা | bn | Core UI |
| Gujarati ગુજરાતી | gu | Core UI |
| Punjabi ਪੰਜਾਬੀ | pa | Core UI |
| Odia ଓଡ଼ିଆ | or | Core UI |
| Assamese অসমীয়া | as | Core UI |

To add more strings for a language: edit the `T` object in `index.html`.

---

## FILE STRUCTURE

```
dataseva/
├── index.html          ← Main website (collectors + companies)
├── admin.html          ← Admin panel (approve/reject)
├── supabase_schema.sql ← Run once in Supabase SQL Editor
└── SETUP.md            ← This file
```

---

## NEXT STEPS (when you're ready to scale)

1. **SMS OTP** — Integrate MSG91 or Twilio for mobile verification (₹0.15/SMS)
2. **GST API** — Verify GSTIN automatically via `https://gstin.io` API (free 100 calls/day)
3. **Email notifications** — Supabase has built-in email triggers (free 100/day)
4. **Aadhaar verification** — Integrate DigiLocker API (requires UIDAI partnership)
5. **UPI payments** — Integrate Razorpay (2% fee, no monthly charge)
6. **Admin role-based access** — Add moderator emails to `admin_users` table

---

*Built for DataSeva — India's Robot Training Data Platform · June 2026*
