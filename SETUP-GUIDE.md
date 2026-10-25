# Green Lodging LLC — Setting Up Your Website

**Time: about 25 minutes. Cost: $0.**

You do not need to understand any of this. Just follow it in order, like a recipe.
If a screen does not look like what I describe, stop and tell me what you see.

Two words you will see a lot:

- **Supabase** — the filing cabinet. It holds the information and the files, and it
  is what checks who is allowed to see what.
- **Netlify** — the shop window. It puts the pages on the internet at a web address.

Both are free.

---

## Before you start

Have these ready:

- The folder I gave you (`greenlodging`). Do not rename anything inside it.
- An email address you can open right now.
- 25 quiet minutes.

---

# PART 1 — The filing cabinet (Supabase)

## Step 1. Make the account

1. Go to **https://supabase.com**
2. Click **Start your project** (green button, top right).
3. Sign up with your email, or with a Google account. Either is fine.
4. Confirm your email if it asks.

## Step 2. Make the project

1. Click **New project**.
2. **Name:** type `green-lodging`
3. **Database Password:** click **Generate a password**, then **copy it and paste it
   somewhere you keep passwords.** You will probably never need it — but if you lose
   it and ever do need it, it cannot be recovered.
4. **Region:** choose **East US (North Virginia)**. It is closest to Brooklyn, so the
   site feels faster.
5. Click **Create new project**.

Now wait. It takes **2 to 3 minutes** to build. Get a coffee. Do not close the tab.

## Step 3. Build the filing drawers

1. On the left edge, click the **SQL Editor** icon (it looks like a database cylinder
   with `SQL` on it). If you only see icons, hover over them — the name appears.
2. Click **New query**.
3. Open the file **`supabase-schema.sql`** from the folder I gave you.
   Open it with TextEdit (Mac) or Notepad (Windows) — not Word.
4. Select **everything** in that file (`Cmd+A` on Mac, `Ctrl+A` on Windows), copy it.
5. Click into the big empty box in Supabase and paste.
6. Click **Run** (bottom right), or press `Cmd+Enter` / `Ctrl+Enter`.

**What should happen:** a message saying **Success. No rows returned**, or a small
table of results. Either is correct.

**If you see red error text:** copy it and send it to me. Do not try to fix it yourself.

> This one script built every drawer, wrote the rules about who may open which drawer,
> and put your five buildings in. You never have to do it again.

## Step 4. Switch off email confirmation

This is what lets your tenants sign up with an invite code instead of waiting on an email.

1. On the left, click **Authentication**.
2. Click **Sign In / Providers** (older versions call this **Providers**).
3. Click **Email**.
4. Find **Confirm email** and turn it **OFF**.
5. Click **Save**.

## Step 5. Copy your two keys

1. On the left, click **Project Settings** (the gear at the bottom).
2. Click **API Keys** (in some versions this is under **API**).
3. You are looking for two things:
   - **Project URL** — looks like `https://abcdefghijkl.supabase.co`
   - **anon** / **publishable** key — a long string. It may start with `sb_publishable_`
     or with `eyJ`.
4. Copy each one using the little copy icon next to it.

> ⚠️ **There is also a key called `service_role` or `secret`. Never copy that one into
> the website, and never send it to anyone — including me.** It is the master key that
> ignores all the security rules. The `anon` key is the one that is safe in public.

## Step 6. Paste them into your website

1. In the folder I gave you, open **`config.js`** with TextEdit or Notepad
   (**not** Word — Word will break it).
2. You will see two lines with `PASTE_..._HERE` in them.
3. Replace **only the text between the quote marks**. Keep the quote marks.

Before:

```js
SUPABASE_URL: "PASTE_YOUR_PROJECT_URL_HERE",
SUPABASE_ANON_KEY: "PASTE_YOUR_ANON_KEY_HERE",
```

After (yours will be different):

```js
SUPABASE_URL: "https://abcdefghijkl.supabase.co",
SUPABASE_ANON_KEY: "sb_publishable_xxxxxxxxxxxxxxxxxxxx",
```

4. While you are in there, fill in your phone and email so tenants can reach you:

```js
EMERGENCY_PHONE: "(718) 555-0134",
OFFICE_EMAIL:    "office@greenlodging.com",
```

5. **Save the file.** Keep the name exactly `config.js`.

---

# PART 2 — The shop window (Netlify)

## Step 7. Put the site on the internet

1. Go to **https://app.netlify.com/drop**
2. Drag the whole **`greenlodging` folder** onto the page.
   (Drag the folder itself — not the files inside it.)
3. Wait about 20 seconds.
4. Netlify shows you a web address like `https://spontaneous-otter-4812.netlify.app`.

**Your website is now live on the internet.** Open it on your phone to prove it.

## Step 8. Give it a proper name

1. Click **Site configuration** → **Change site name**.
2. Type `greenlodging` (or `greenlodgingllc` if that one is taken).
3. Your address becomes **`https://greenlodging.netlify.app`**.

Write that address down. It is what you give tenants.

## Step 9. Tell Supabase about the address

This makes "forgot my password" emails work properly.

1. Back in Supabase: **Authentication** → **URL Configuration**.
2. Put your Netlify address in **Site URL**: `https://greenlodging.netlify.app`
3. Click **Save**.

---

# PART 3 — Make yourself the owner

Right now the website exists but nobody has an account.

## Step 10. Sign up on your own website

1. Open your website address.
2. Click the **Management** tab.
3. There is no "create account" button on purpose — so do this instead:
   click **Resident**, then **Set up your account with an invite code**.
4. Fill in your name, your email, and a password you will remember.
   For the invite code, type anything — `SETUP` will do.
5. Click **Create my account**.
6. It will say the code did not work. **That is expected.** Your account was still created.

## Step 11. Promote yourself

1. Go back to Supabase → **SQL Editor** → **New query**.
2. Paste this, putting **your** email between the quote marks:

```sql
update public.profiles set role = 'owner' where email = 'your-email@example.com';
```

3. Click **Run**. It should say `UPDATE 1`.

> If it says `UPDATE 0`, the email does not match. Run
> `select email from public.profiles;` to see exactly what was saved.

## Step 12. Sign in as the owner

1. Go back to your website and refresh the page.
2. Click **Management**, sign in with that email and password.

You should now see **Today**, with your five buildings already loaded and a checklist
telling you what to do next.

**You are done with setup.** Everything from here is normal use.

---

# PART 4 — Your first real day

Work through the checklist on the Today page:

1. **Buildings → Add unit.** Every apartment and every store, in all five buildings.
   Include vacant ones.
2. **Add lease** on each occupied unit. Tenant name, rent, start date, end date.
   *This is the important one* — every reminder in the system is calculated from
   these dates.
3. **Utilities → Add account.** One per building per utility. Con Edison, National
   Grid, NYC DEP. Put in the day of the month each one normally bills.
4. **Rent → Record.** As checks come in.
5. **People → Create invite code.** One per apartment. Hit **Copy slip** and you get
   a ready-made note to print and hand to the tenant.

---

# Adding your property manager

1. Have them go to your website and create an account the same way you did (Step 10).
2. Then **People → Accounts → Change role → Property manager.**

They can do everything you can, except delete records and change people's roles.

---

# Things worth knowing

**Is it really free?**
Yes, on these limits: 500 MB of records, 1 GB of scanned files, 50,000 sign-ins a month.
For five buildings that is years of use. Netlify is free for 100 GB of traffic a month —
you will not come close.

**The one thing to watch:** a free Supabase project **pauses after 7 days with nobody
using it.** If you and your tenants use it weekly, it never pauses. If it does pause,
open Supabase and click **Restore** — nothing is lost.

**Can tenants see each other's information?**
No. I tested this specifically. A tenant asking the database directly for another
apartment's lease gets nothing back — not an error, just nothing. The rule lives in
the database, so it holds no matter what anybody types into the website.

**What tenants can see:** their own lease, their own rent record and receipts, utility
bills metered to their own apartment, repairs they reported, and documents you
explicitly tick as shared.

**What tenants can never see:** any other apartment, your other buildings, your utility
accounts, invite codes, or any document you did not share.

**Changing the site later.** Edit the files, then go to Netlify → **Deploys** → drag
the folder on again. It replaces the old version in about 20 seconds. Your data is
untouched — it lives in Supabase, not in the website files.

**Backups.** Rent → **Download this month (CSV)** gives you a spreadsheet any
accountant or lawyer can read. Do it monthly and keep it in a folder.

---

# Turning on text-message login later

Only when you want to spend roughly $5/month.

1. Make a Twilio account, get a US phone number, and register for A2P 10DLC
   (US law requires it for business texts).
2. In Supabase: **Authentication → Sign In / Providers → Phone**, switch it on, and
   paste in your Twilio Account SID, Auth Token, and Message Service SID.
3. In `config.js`, change `ENABLE_SMS_LOGIN: false` to `ENABLE_SMS_LOGIN: true`.
4. Drag the folder onto Netlify again.

Tenants then sign in with their phone number and a texted code instead of a password.
Nothing else changes and no data is lost.

---

# If something goes wrong

| What you see | What it means |
|---|---|
| "config.js still has the placeholder text in it" | Step 6 was not saved. Open config.js again. |
| "That email and password do not match" | Typo, or you signed up with a different email. |
| Page loads but everything is empty | You are signed in but not set to `owner` yet — redo Step 11. |
| "Your account is not allowed to do that" | You are signed in as a manager or tenant, not the owner. |
| Site says it cannot connect | The Supabase project may have paused. Open Supabase and click Restore. |

For anything else, tell me exactly what the screen says and I will tell you what to do.
