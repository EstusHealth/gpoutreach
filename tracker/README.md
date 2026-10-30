# Driving OT Pipeline

Lead and nurture tracker for Driving on the Spectrum: client leads, GP practices as referrers, and reporting back to GPs.

- `index.html` is the tracker page. It runs inside claude.ai as an artifact and talks to Supabase through the owner's Supabase connector, so it does not work when opened as a plain web page.
- `supabase/migrations/0001_init.sql` is the database schema (project `xlxqukjktwkcpyjghwqs`, Sydney).

The public Supabase API is locked: row level security only allows emails listed in `private.app_owners`, which is empty.
