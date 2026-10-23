# Thomas Phiri — Marketing Engineer Portfolio (Enquiry & Call Request Upgrade)

Responsive, single-file portfolio website built with HTML, CSS and vanilla JavaScript. No build step or external UI library is required.

## Included
- Premium Marketing Engineer positioning and responsive layout
- Filterable project cards and expandable interactive case studies
- Existing public project background retained: BlueMagnet, AI Technical SEO & Schema Automation, EMK LINKS Art Gallery & Marketing Intelligence, IT Support Performance Analysis, and Sales Performance Analysis
- Three scoped consulting offers and a clear contact route
- Enquiry form for both consulting and employment/collaboration opportunities
- Optional 20-minute introductory-call request with preferred date, time window and call format
- Direct email, phone and WhatsApp contact options
- Conversion-event hooks and a local browser event log; optional Google Analytics 4 configuration
- Light/dark theme, mobile navigation, accessibility basics and reduced-motion support
- Both iConnect SA projects are excluded

## Test locally
Open `index.html` in a modern browser. For a local server, run `python -m http.server 8000` in this folder and visit `http://localhost:8000`.

## Deploy with GitHub Pages
1. Download and unzip the package.
2. Open the repository: https://github.com/thomasphiri52/Marketing-engineer-portfolio-
3. Upload `index.html` to the repository root (replace the existing file if prompted), then commit the change to `main`.
4. In GitHub, open **Settings → Pages**. Under **Build and deployment**, choose **Deploy from a branch**, select branch `main` and folder `/(root)`, then save.
5. Wait for the Pages deployment to finish. Expected address: https://thomasphiri52.github.io/Marketing-engineer-portfolio-/ . This is an expected URL, not confirmation that deployment has happened.

## Enquiry form and call requests
The form validates the required fields and opens the visitor’s configured email application with a prepared message addressed to `PHIRITHOMAS589@GMAIL.COM`. The visitor must press Send. If their email app does not open, the **Copy enquiry text instead** button can be used after submitting to copy the message (or select it from the fallback text area).

When a visitor checks the introductory-call option, they can include a preferred date, time window (SAST / UTC+2) and format. This is a **call request only**: the site does not check a calendar, reserve a slot, send confirmations or store enquiries on a server. Thomas must confirm the time by replying. For automated bookings, reminders, spam protection or central lead storage, connect a scheduling/form provider or backend.

## Conversion tracking
The site pushes events to `window.dataLayer` and retains the most recent 200 events in the current browser’s local storage under `tp_portfolio_events_v1`. This is local diagnostic data, not shared analytics. To send events to Google Analytics 4, configure a real property, set `ga4MeasurementId` in the `window.PORTFOLIO_CONFIG` block to your actual `G-XXXXXXXXXX` Measurement ID, and add the official Google tag snippet in the `<head>`. Until a real property is configured, no GA4 events are sent. Update your privacy notice/consent setup to match applicable requirements before enabling third-party analytics.

## Before publishing
- Confirm the contact details and service descriptions.
- Test project/demo links, WhatsApp, email and the call-request form on desktop and mobile.
- Test the preferred-date field and confirm the email clearly says the time is not confirmed.
- Replace or supplement case-study descriptions with verified screenshots, data and outcomes when available; do not publish unverified performance metrics as results.
- No portfolio file has been pushed to GitHub by this package creation step.
