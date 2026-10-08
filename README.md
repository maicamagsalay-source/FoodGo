# Lamón – Filipino Cuisine Ordering and Payment System

Flutter + Supabase (Postgres, Auth, Storage, Edge Functions) + PayMongo.
State management: **Provider** (simplest option).

## 1. Open in VS Code
1. Install Flutter (flutter.dev) and the VS Code extensions **Dart** and **Flutter** (VS Code will suggest them).
2. Unzip, then **File > Open Folder...** and choose the `foodgo` folder.
3. Open the terminal (Ctrl+`) and run (Windows PowerShell):
   ```powershell
   .\setup.ps1
   ```
   If PowerShell blocks it: `Set-ExecutionPolicy -Scope Process Bypass` then run it again.
   (This runs `flutter create .`, `flutter pub get`, and adds the internet/link permissions to the Android manifest.)
4. After section 2 below, choose a device (bottom-right of VS Code) and press **F5**.

## 2. Supabase
1. Create a project at supabase.com.
2. SQL Editor → paste and run `supabase/schema.sql` (tables, security rules, order function, image bucket, sample menu).
   If your project already has the schema, run `supabase/add_cash_on_delivery.sql` in the SQL Editor before updating the app.
3. Project Settings → API: keep the **Project URL** and **publishable (anon) key** handy. Press F5 in VS Code and enter both when prompted. For a terminal run, pass them as Dart defines:
   ```powershell
   flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```
   The app uses these values for Supabase Auth and profile access. Never use the `service_role` key in the app.
4. Authentication → Providers → Email. For easy testing you can turn **Confirm email** off.
5. Register an account in the app, then make it admin in the SQL Editor:
   ```sql
   update profiles set role = 'admin' where email = 'you@example.com';
   ```
   Log in again: admins go straight to the Admin dashboard.

## 3. PayMongo + Edge Functions
1. Create a PayMongo account and use **test mode** keys first.
2. Install the Supabase CLI, then:
   ```bash
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   supabase secrets set PAYMONGO_SECRET_KEY=sk_test_xxx
   supabase secrets set PAYMENT_RETURN_URL=https://your-simple-thank-you-page
   supabase functions deploy create-payment
   supabase functions deploy paymongo-webhook --no-verify-jwt
   ```
3. PayMongo Dashboard → Developers → Webhooks → add
   `https://YOUR_PROJECT_REF.supabase.co/functions/v1/paymongo-webhook`
   with events `checkout_session.payment.paid` and `payment.failed`.
   Copy the webhook's signing secret, then:
   ```bash
   supabase secrets set PAYMONGO_WEBHOOK_SECRET=whsk_xxx
   ```
4. `PAYMENT_RETURN_URL` is where PayMongo sends the customer after paying. Any simple public page works
   (the app does not depend on it: it watches the database and shows the result automatically).

## Payment flow
Flutter → `place_order()` (order and payment method saved) → PayMongo orders continue to Checkout and the webhook updates payment status; Cash on Delivery orders show an order confirmation and are paid in cash at delivery.

The PayMongo secret key exists only as a Supabase secret. It is never in the Flutter app.

## Menu categories
The sample categories include **Home made**. In an existing project, sign in as admin, open **Foods → Manage Categories → Add Category**, and add `Home made`. When adding or editing a food, choose that category to show it separately in the customer menu. Existing foods keep their current categories.

## Notes
- Delivery fee is ₱49: change it in `place_order()` (schema.sql) and `CartProvider.deliveryFeeAmount`.
- Prices and totals are calculated in the database, so a modified app can't change what it pays.
- Admin pages are protected twice: the app checks `role = 'admin'` and the database rules (RLS) block non-admins.
- Profile picture is a letter avatar to keep things simple (Storage upload is used for food images).
- I could not compile or run this here. Expect to fix small issues on first `flutter run`, and verify the PayMongo
  event names/payload in your dashboard's webhook logs, since I wrote the webhook from PayMongo's documented format.
