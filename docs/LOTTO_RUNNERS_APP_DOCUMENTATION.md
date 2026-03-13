## Lotto Runners – Application Documentation

### 1. Application Overview

**Lotto Runners** is a multi-role service platform that connects people who need errands done with a network of runners who can fulfill those errands, under the supervision of administrators.

- **Platform type**: On-demand errands and services marketplace.
- **Clients**:
  - **Customers** use the app to request services.
  - **Runners** use the app to accept and complete those services.
  - **Admins** manage users, services, finance, and compliance.
- **Typical services**:
  - Shopping and deliveries
  - Transport and bus bookings
  - Queue sitting and license-disc renewals
  - Document- and elderly-assistance services
  - Miscellaneous/special errands and custom orders

---

### 2. Technical Stack (High-Level)

- **Frontend / App**: Flutter (Dart, mobile + web + desktop launcher icons)
- **Backend / Auth / Database**: Supabase
- **Maps & Location**: Google Maps, geolocation, and geocoding
- **Notifications**: Local notifications (and integrations with push / background location)
- **Payments**: PayToday (web-based payment flow)
- **Target platforms**: Android, iOS, Web (with Windows/macOS icons prepared)

You can treat Lotto Runners as a Supabase-backed Flutter super-app for errand logistics, payments, and operations.

---

### 3. User Roles and Responsibilities

#### 3.1 Customers

**Who they are**: End users who need tasks done.

**Key capabilities**:

- **Account & Profile**
  - Register/login via Supabase (email/password or other auth flows).
  - Manage personal details, contact info, and addresses.
  - View historical orders and payment receipts.

- **Requesting Services / Errands**
  - Create new **errand requests** with:
    - Service type (shopping, transport, bus ticket, queue sitting, license disc, delivery, elderly assistance, documents, special/custom orders).
    - Pickup and drop-off locations (via maps/autocomplete).
    - Time and date (immediate or scheduled).
    - Additional notes or instructions.
  - Attach images or documents (e.g. prescriptions, documents for renewal).
  - See estimated costs/fees where available.

- **Transport & Bus Bookings**
  - Request point-to-point transport.
  - Book bus seats or tickets (depending on configuration and data).
  - View departure/arrival information if provided by the system.

- **Order Tracking**
  - See order/errand status: pending, accepted, in progress, completed, cancelled.
  - Track runner location on a map (for supported tasks) or see status updates.
  - Receive notifications about status changes and arrivals.

- **Payments**
  - Pay for errands via **PayToday** web flow.
  - View payment success/failure states.
  - Access receipts and basic transaction history.

- **Ratings / Feedback**
  - Rate runners and the overall service after completion.
  - Submit feedback or complaints for admin review.

---

#### 3.2 Runners

**Who they are**: Service providers who fulfill errands and transport/bus/other tasks.

**Key capabilities**:

- **Registration & Verification**
  - Apply to become a runner:
    - Provide personal details, contact info, and identification documents.
    - Upload required documents (e.g. ID, driver’s license, car documents).
  - Wait for **admin verification/approval** before full access.
  - Maintain a runner profile (photo, vehicle info, service area).

- **Job Discovery & Acceptance**
  - View list/map of **available errands** in their area.
  - Filter by service type, distance, or payout (depending on UI).
  - See detailed job info:
    - Pickup/drop-off points
    - Customer notes
    - Expected earnings/fees.
  - Accept or decline errands.

- **Job Management & Navigation**
  - Manage **active jobs**:
    - Start job, mark in-progress, complete.
    - Update intermediate statuses (e.g. arrived at store, purchased items, en route).
  - Use integrated **maps and location**:
    - See routes and navigation via Google Maps.
    - Share/rely on real-time location for customer tracking (if enabled).

- **Wallet & Earnings**
  - Maintain a **runner wallet**:
    - View total earnings, available balance, pending amounts.
    - See per-job earnings and transaction history.
  - **Withdraw funds**:
    - Request withdrawals to external payment channels/bank accounts.
    - See withdrawal status (pending/approved/paid).

- **Notifications & Scheduling**
  - Receive notifications for:
    - New nearby jobs.
    - Job acceptance and changes.
    - Payment and wallet updates.
  - Optionally manage availability (online/offline) to control job offers.

---

#### 3.3 Admins

**Who they are**: Internal staff or operators managing the entire Lotto Runners ecosystem.

**Key capabilities**:

- **User & Runner Management**
  - View and manage **customers** and **runners**.
  - Review and verify runner applications:
    - Validate documents and identity.
    - Approve, reject, or request more information.
  - Suspend or re-enable users if required for policy or safety reasons.

- **Errands & Operations Oversight**
  - Monitor all **errands and jobs**:
    - Status dashboard (pending, in progress, completed, cancelled).
    - View details and timelines for each job.
  - Manually intervene when necessary:
    - Reassign jobs.
    - Cancel or modify jobs under special circumstances.
  - Oversee **transport and bus bookings**:
    - Check routes, capacity (if configured), and bookings.
    - Handle disputes or failed trips.

- **Payments, Withdrawals & Accounting**
  - Oversee **customer payments**:
    - Monitor successful and failed PayToday transactions.
    - Reconcile payments vs. jobs.
  - Manage **runner payouts**:
    - Approve or reject withdrawal requests.
    - Record reasons for rejections/adjustments.
  - Run basic accounting and export data (for finance teams).

- **Analytics & Reporting**
  - View operational dashboards:
    - Number of active users, runners, and jobs.
    - Revenue, payouts, and margins (depending on reporting setup).
    - Service category usage (e.g. which services are most used).
  - Use charts/metrics for business decisions (e.g. where to recruit more runners).

- **Configuration & Compliance**
  - Manage **service categories**, pricing rules, and fees.
  - Configure **RLS / access policies** in Supabase (ensuring customers/runners/admins see only what they should).
  - Ensure **compliance with BIPA, Google Play, and Apple policies**:
    - Privacy Policy and Terms of Service.
    - Data usage and safety disclosures.
  - Handle support tickets, complaints, and escalations.

---

### 4. Core Functional Areas

#### 4.1 Errands & Services Module

- Create, assign, and track errands for customers and runners.
- Support multiple categories:
  - Shopping
  - Transport
  - Bus bookings
  - Documentation / license discs
  - Queue sitting
  - Elderly assistance
  - Deliveries
  - Special/custom errands
- Use geolocation and Google Maps for:
  - Address selection (autocomplete).
  - Distance estimation and trip context.
- Integrate with Supabase for:
  - Storage of jobs, statuses, and events.
  - Role-based access (via RLS and policies).

#### 4.2 Payments & Wallets

- **Customer side**
  - Launch PayToday payment flow for job charges.
  - Confirm payment success/failure and link to specific jobs.
  - Allow customers to view receipts and basic transaction history.

- **Runner side**
  - Maintain a **wallet** of accrued earnings.
  - View per-job earnings and payouts.
  - Request withdrawals and see their status.

- **Admin side**
  - Oversight over financial flows and reconciliation.
  - Manual interventions where needed (e.g. resolving disputes, adjusting payouts).

#### 4.3 Location, Maps & Tracking

- Use Google Maps Flutter, geolocator, and geocoding to:
  - Pick addresses and convert between addresses and coordinates.
  - Show runner and trip paths.
- Integrate with notification and background-location tooling so:
  - Users can be notified of status changes.
  - Tracking persists during critical phases of a job.

#### 4.4 Notifications & Communication

- Use flutter_local_notifications and related tooling.
- Notify:
  - Order creation, acceptance, and assignment.
  - Job status transitions (on the way, arriving, completed).
  - Payment and withdrawal updates.

#### 4.5 Admin & Analytics

- Provide admin dashboards for:
  - Job monitoring.
  - User and runner management.
  - Verification workflows.
- Provide charts and reports (e.g. via fl_chart) for:
  - Volume of errands over time.
  - Revenue vs. payouts.
  - Runner performance.

---

### 5. End-to-End Flow Example

1. A **Customer** creates a new errand, specifying service type, locations, time, and notes.
2. The job is stored in Supabase and appears as **available** to nearby **Runners**.
3. A **Runner** accepts the job, the status updates, and the Customer is notified.
4. The Runner navigates using integrated maps and performs the task (shopping, transport, etc.).
5. The Customer pays (if not prepaid) via PayToday, and the Runner completes the job.
6. The Runner’s wallet is credited; the Customer can rate the experience.
7. **Admins** oversee the entire lifecycle, ensuring jobs run smoothly, users are verified, and finances reconcile correctly.

---

### 6. Summary

Lotto Runners is a Supabase-backed Flutter application designed as a multi-role errands and services marketplace.  
Customers request services, Runners fulfill them, and Admins manage verification, operations, and finances across the entire ecosystem.

