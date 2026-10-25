# Green Lodging – Property Management Website

A private web app that lets a property owner run a rental business from one place: buildings, apartments and shops, tenants, leases, monthly rent, operating costs, utilities, documents and tenant complaints.

It is a static website (plain HTML + JavaScript, no build step) hosted on **Netlify**, with **Supabase** as the backend for the database, user logins and file storage.

> **Privacy note:** this repository contains real owner data (`seed-01-fulton-and-pacific.sql`: building addresses, tenant names, rent and arrears). Keep the repository **private**.

---

## Why this exists

Rent rolls, arrears letters, leases, bills and tenant requests usually live in spreadsheets, PDFs and email threads. This app replaces that with one login-protected site so the owner can:

- see at a glance what is owed, what has been paid and what is late,
- keep each building's income and expenses together,
- give property managers and tenants access to only what they should see.

## What it does

| Area | What you can do |
|---|---|
| **Buildings & units** | Track buildings and the apartments/shops in each, with notes. |
| **Tenants & leases** | Record tenants, lease dates and rent. A unit can hold a current rent and tenant name *before* the lease paperwork arrives (no invented dates). |
| **Rent tracking** | Monthly rent per unit, split into the government share and the tenant share, plus what the tenant actually paid and free-text notes (part payments, disputes). |
| **Other charges** | Non-rent charges such as tax escalations, late fees and legal costs. |
| **Building expenses** | Maintenance, insurance, taxes, mortgage and other operating costs per building. |
| **Utilities** | Utility accounts and bills per building. |
| **Documents** | Upload and store leases, letters and bills in Supabase Storage. |
| **Complaints** | Tenants raise issues; managers post updates until resolved. |
| **Invites** | Invite a tenant or manager to a unit so they can sign up. |
| **Roles** | Three roles: **owner** (everything), **manager** (day-to-day), **tenant** (own unit only). Enforced in the database with Row Level Security, not just hidden in the page. |

## Tech stack

- **Frontend:** `index.html` + `app.js` (vanilla JavaScript), `@supabase/supabase-js` loaded from jsDelivr
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Row Level Security)
- **Hosting:** Netlify (static)

## Repository contents

| File | Purpose |
|---|---|
| `index.html` | The site: pages, styles and the config block for your Supabase keys |
| `app.js` | Application logic |
| `supabase-schema.sql` | Base database: tables, roles, security policies, file storage |
| `migration-02-government-rent.sql` | Splits rent into government and tenant shares |
| `migration-03-costs-and-charges.sql` | Building expenses and non-rent charges |
| `migration-04-rent-without-lease.sql` | Lets a unit hold rent and tenant without a lease |
| `migration-05-payment-columns.sql` | Tenant payment amount and notes per unit |
| `seed-01-fulton-and-pacific.sql` | The owner's real data (1403 Fulton St and 2165 Pacific St) |
| `SETUP-GUIDE.md` | Plain-English walkthrough with screenshots-in-words for non-technical users |

---

## Set up on a new computer

### Prerequisites

- [Git](https://git-scm.com/downloads)
- A GitHub login with access to this private repo
- A [Supabase](https://supabase.com) account (free)
- Optional: a [Netlify](https://netlify.com) account (free) to put it online
- Python 3 **or** Node.js, only to serve the files locally

### 1. Get the code

```bash
git clone https://github.com/ronithjuluri18/green-lodging.git green_lodging
cd green_lodging
```

When prompted for a password, use a GitHub personal access token (Settings → Developer settings → Personal access tokens).

### 2. Create the Supabase project

1. In Supabase, create a new project (e.g. `green-lodging`).
2. Open **SQL Editor → New query** and run these files **in this order**, one at a time (paste the contents, click Run):
   1. `supabase-schema.sql`
   2. `migration-02-government-rent.sql`
   3. `migration-03-costs-and-charges.sql`
   4. `migration-04-rent-without-lease.sql`
   5. `migration-05-payment-columns.sql`
   6. `seed-01-fulton-and-pacific.sql` (only if you want the owner's real data loaded; run once)
3. Go to **Authentication → Providers → Email** and turn **off** "Confirm email" so new users can sign in straight away.
4. Go to **Project Settings → API** and copy:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **Publishable / anon key** (`sb_publishable_…` or starts with `eyJ`)

   Never use the `secret` or `service_role` key in this project.

### 3. Add your keys to the site

Open `index.html` and find the `GL_CONFIG` block near the top:

```js
window.GL_CONFIG = {
  SUPABASE_URL: "PASTE_YOUR_PROJECT_URL_HERE",
  SUPABASE_ANON_KEY: "PASTE_YOUR_ANON_KEY_HERE",
  COMPANY_NAME: "Green Lodging LLC",
  EMERGENCY_PHONE: "",
  OFFICE_EMAIL: "",
};
```

Replace the two placeholders with your values. The publishable key is designed to be public (it is visible to anyone who opens the site); your data is protected by the database's security rules. Keep real keys out of commits you intend to share publicly.

### 4. Run it locally

From the project folder, either:

```bash
python3 -m http.server 8000
```
or
```bash
npx serve .
```

Then open <http://localhost:8000>.

Add `http://localhost:8000` under Supabase **Authentication → URL Configuration** (Site URL / Redirect URLs) if sign-in redirects fail.

### 5. Make yourself the owner

1. On the site, sign up with your email.
2. In Supabase **SQL Editor**, run:
   ```sql
   update public.profiles set role = 'owner' where email = 'YOUR-EMAIL-HERE';
   ```
3. Sign out and back in. You now see everything. Invite a manager or tenants from the app.

### 6. Put it online (Netlify)

1. In Netlify choose **Add new site → Deploy manually** and drag the project folder in, **or** **Import from Git** and pick this repo (no build command, publish directory `.`).
2. Copy the Netlify address (e.g. `https://your-site.netlify.app`) and add it in Supabase **Authentication → URL Configuration** as the Site URL and a Redirect URL.

For the full beginner-friendly walkthrough, see [`SETUP-GUIDE.md`](SETUP-GUIDE.md).

---

## Everyday workflow

```bash
git pull                      # get the latest
# ...edit files...
git add -A
git commit -m "Describe the change"
git push                      # Netlify redeploys automatically if linked to the repo
```

Database changes: add a new numbered file (e.g. `migration-06-….sql`), run it in the Supabase SQL Editor, and commit it so the history stays in order.

## Security checklist

- Repository stays **private**.
- Only the publishable/anon key goes in the site. Never commit `service_role` or secret keys, passwords, or `.env` files.
- Don't remove or loosen the Row Level Security policies in `supabase-schema.sql`.
- Back up the database from Supabase (Project → Database → Backups) as well as the code.

## Troubleshooting

- **"config still has the placeholder text":** keys in `index.html` are not filled in or have a typo.
- **Can sign up but see nothing:** you have not been promoted to `owner` yet (step 5).
- **Sign-up asks to confirm email:** "Confirm email" is still on in Supabase (step 2.3).
- **A SQL file errors:** the files must run in order; each is safe to re-run.
