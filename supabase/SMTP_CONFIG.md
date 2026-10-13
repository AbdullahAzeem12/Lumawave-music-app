# Custom SMTP Configuration Guide for Pulse (Supabase Auth)

This guide walks you through configuring **Resend** (or alternatively **Gmail SMTP**) in your Supabase project (`hacpudduvbyyfrehrdzy`). Once configured, you will be able to send thousands of confirmation emails without hitting any rate limits.

---

## Option 1: Resend (Officially Recommended by Supabase)
Resend gives you **3,000 free emails per month** (100 emails/day) with instant delivery.

### Step 1: Get your Resend API Key
1. Go to [resend.com](https://resend.com) and sign up (takes 10 seconds via GitHub or Google).
2. Go to **API Keys** in the left sidebar: [resend.com/api-keys](https://resend.com/api-keys).
3. Click **Create API Key**.
   - **Name**: `Supabase Pulse`
   - **Permission**: `Full Access`
4. Copy the generated key (starts with `re_...`).

### Step 2: Configure SMTP in Supabase
1. Open your [Supabase SMTP Settings](https://supabase.com/dashboard/project/hacpudduvbyyfrehrdzy/settings/auth).
2. Scroll to the **SMTP Settings** section.
3. Toggle **Enable Custom SMTP** to **ON**.
4. Fill in the exact fields:
   | Setting | Value |
   |---|---|
   | **Sender email** | `onboarding@resend.dev` *(or your custom domain email)* |
   | **Sender name** | `Pulse Music` |
   | **Host** | `smtp.resend.com` |
   | **Port** | `465` |
   | **Minimum duration between emails** | `0` or `10` seconds |
   | **User** | `resend` |
   | **Password** | *Paste your Resend API Key (`re_...`)* |
5. Click **Save**.

---

## Option 2: Gmail SMTP (Free Alternative, No Domain Required)
If you already have a Gmail account, you can use Gmail's SMTP server to send up to 500 emails/day for free:

### Step 1: Create a Google App Password
1. Go to your [Google Account Security](https://myaccount.google.com/security).
2. Ensure **2-Step Verification** is enabled.
3. Search for **App passwords** (or go to [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)).
4. Create a new App password named `Pulse Music`.
5. Copy the 16-character generated password (e.g., `abcd efgh ijkl mnop`).

### Step 2: Configure in Supabase
1. Open [Supabase SMTP Settings](https://supabase.com/dashboard/project/hacpudduvbyyfrehrdzy/settings/auth).
2. Toggle **Enable Custom SMTP** to **ON**.
3. Fill in:
   | Setting | Value |
   |---|---|
   | **Sender email** | *your-email@gmail.com* |
   | **Sender name** | `Pulse Music` |
   | **Host** | `smtp.gmail.com` |
   | **Port** | `465` |
   | **User** | *your-email@gmail.com* |
   | **Password** | *Your 16-character Google App Password (no spaces)* |
4. Click **Save**.

---

## Step 3: Increase Rate Limits in Supabase
Once Custom SMTP is enabled, increase your rate limits to prevent any throttling:

1. Open [Supabase Rate Limits](https://supabase.com/dashboard/project/hacpudduvbyyfrehrdzy/auth/rate-limits).
2. Adjust:
   - **Email signups per hour**: Change `30` to `300`
   - **Token verifications per hour**: Change `30` to `300`
   - **Email OTP per hour**: Change `30` to `300`
3. Click **Save**.

---

## Step 4: Apply the Branded Pulse Email Template
Make your confirmation emails look stunning and professional:

1. Open [Supabase Email Templates](https://supabase.com/dashboard/project/hacpudduvbyyfrehrdzy/auth/templates).
2. Select **Confirm signup**.
3. Replace the subject with:
   ```text
   Confirm your Pulse Music Account
   ```
4. Replace the body with the HTML content from:
   [`supabase/EMAIL_TEMPLATE.html`](file:///c:/Users/khero/StudioProjects/Pulse/supabase/EMAIL_TEMPLATE.html)
5. Click **Save**.
