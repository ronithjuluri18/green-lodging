# Green Lodging – Property Management Website

A web app for a property owner to manage buildings, units, tenants, leases, rent, costs and charges.

- **Frontend:** static site (`index.html`, `app.js`) hosted on Netlify
- **Backend:** Supabase (Postgres, auth, storage)

## Database setup (run in the Supabase SQL Editor, in order)

1. `supabase-schema.sql`
2. `migration-02-government-rent.sql`
3. `migration-03-costs-and-charges.sql`
4. `migration-04-rent-without-lease.sql`
5. `migration-05-payment-columns.sql`
6. `seed-01-fulton-and-pacific.sql` (real owner data – run once)

See `SETUP-GUIDE.md` for the full step-by-step Supabase + Netlify walkthrough.

## Notes

- Never commit the Supabase `service_role` key. Only the public/anon (publishable) key belongs in the frontend.
- This repository is private because the seed file contains real tenant and building data.
