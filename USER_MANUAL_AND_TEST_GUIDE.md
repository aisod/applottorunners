# Lotto Runners - User Manual & Test Strategy Guide

## Table of Contents
1. [App Overview](#app-overview)
2. [User Types & Roles](#user-types--roles)
3. [Test Strategy by User Type](#test-strategy-by-user-type)
4. [Quick Test Checklist](#quick-test-checklist)

---

## App Overview

**Lotto Runners** is a comprehensive errand-running platform built with Flutter and Supabase that connects customers with verified runners to complete everyday tasks efficiently and securely. The platform facilitates on-demand errand services, transportation bookings, and provides a complete marketplace for task completion.

### Core Purpose
- **For Customers**: Post errands and tasks that need to be completed by others
- **For Runners**: Browse available errands, accept jobs, and earn money by completing tasks
- **For Businesses**: Access commercial errand services and transportation solutions
- **For Admins**: Manage the platform, verify users, track payments, and monitor platform health

### Key Features
- **Errand Management**: Post, track, and manage errands with real-time status updates
- **Runner Marketplace**: Browse and accept available errands with smart filtering
- **Real-time Communication**: Chat system for customer-runner communication
- **Payment System**: Integrated payment tracking and wallet management
- **Transportation Services**: Book shuttles, point-to-point rides, and bus services
- **Verification System**: Runner verification process with document upload
- **Admin Dashboard**: Comprehensive platform management tools
- **Notifications**: Real-time alerts for status changes and new opportunities

---

## User Types & Roles

### 1. Individual User
**Purpose**: Personal errand posting and task management

**Capabilities**:
- Sign up and create profile
- Post errands with detailed information
- Track errand status (Posted → Accepted → In Progress → Completed)
- Communicate with runners via chat
- View order history
- Manage profile and settings
- Book transportation services
- Cancel errands (with restrictions)

**Limitations**:
- Cannot accept errands (only runners can)
- Cannot verify other users
- Cannot access admin features

---

### 2. Business User
**Purpose**: Commercial errand services and business transportation needs

**Capabilities**:
- All Individual user features
- Post business-related errands
- Book transportation services for business needs
- Manage multiple errands simultaneously
- Access business-specific features
- Contract bookings for recurring services

**Limitations**:
- Cannot accept errands (only runners can)
- Cannot verify other users
- Cannot access admin features

---

### 3. Runner User
**Purpose**: Complete errands for customers and earn money

**Capabilities**:
- Sign up and apply for verification
- Browse available errands
- Filter errands by category, vehicle requirements, location
- Accept errands (up to 3 active errands at a time)
- Manage accepted errands (Start → Complete workflow)
- Chat with customers
- View earnings and wallet balance
- Track analytics (success rate, total earnings, active jobs)
- Accept transportation bookings (up to 3 active bookings)
- Cancel accepted errands/bookings (with restrictions)
- View admin messages

**Limitations**:
- Cannot post errands (only customers can)
- Maximum 3 active errands at a time
- Maximum 3 active transportation bookings at a time
- Must be verified by admin to access all features
- Cannot accept errands requiring vehicles if they don't have one

**Verification Requirements**:
- Submit application with personal information
- Upload verification documents
- Vehicle documentation (if applicable)
- Wait for admin approval

---

### 4. Admin User
**Purpose**: Platform management and oversight

**Capabilities**:
- Access comprehensive admin dashboard
- **User Management**: View, search, filter, and manage all users
- **Errand Oversight**: Monitor all errands, filter by status/category
- **Payment Tracking**: View transactions, process refunds, track revenue
- **Runner Verification**: Approve/reject runner applications
- **Analytics Dashboard**: View platform metrics, user counts, completion rates
- **Provider Accounting**: Track runner earnings and commissions
- **Admin Messaging**: Send messages to runners
- **Transportation Management**: Oversee transportation services and bookings
- **Settings Management**: Configure platform settings

**Limitations**:
- Cannot post errands (unless also registered as Individual/Business)
- Cannot accept errands (unless also registered as Runner)
- Must have admin role assigned in database

---

## Test Strategy by User Type

### Testing as Individual User

#### 1. Registration & Authentication
- [ ] **Sign Up Test**
  - Navigate to sign up page
  - Select "Individual" as user type
  - Fill in: Name, Email, Password, Phone (optional)
  - Submit and verify account creation
  - Check email verification (if enabled)
  
- [ ] **Login Test**
  - Log in with created credentials
  - Verify redirect to Individual home page
  - Check profile information displays correctly

#### 2. Profile Management
- [ ] **View Profile**
  - Navigate to Profile tab
  - Verify all profile information displays
  - Check avatar/image display
  
- [ ] **Edit Profile**
  - Update name, phone number
  - Upload/change profile picture
  - Save changes and verify persistence

#### 3. Errand Posting
- [ ] **Post Basic Errand**
  - Navigate to "Post Errand" page
  - Fill in: Title, Description, Category
  - Set price and time limit
  - Add pickup and delivery locations
  - Submit and verify errand appears in "My Orders"
  
- [ ] **Post Errand with Images**
  - Create new errand
  - Upload one or more images
  - Verify images display correctly
  - Submit and check images appear in errand details

- [ ] **Post Errand with Vehicle Requirement**
  - Create errand requiring vehicle
  - Verify vehicle requirement flag is set
  - Check that only runners with vehicles can see it

- [ ] **Post Different Category Errands**
  - Test: Grocery, Delivery, Document, Shopping, Other
  - Verify category-specific fields appear
  - Check category filtering works

#### 4. Order Management
- [ ] **View My Orders**
  - Navigate to "My Orders" tab
  - Verify all posted errands appear
  - Check status indicators (Posted, Accepted, In Progress, Completed)
  
- [ ] **Track Errand Status**
  - Post an errand
  - Wait for runner to accept
  - Verify status changes to "Accepted"
  - Check notifications received
  - Verify status updates in real-time

- [ ] **Chat with Runner**
  - Open accepted errand
  - Click "Chat" button
  - Send messages to runner
  - Verify messages appear in real-time
  - Check message history persists

- [ ] **Mark Errand as Completed**
  - Wait for runner to mark as "In Progress"
  - Wait for runner to mark as "Completed"
  - Verify completion status
  - Check payment processing (if applicable)

- [ ] **Cancel Errand**
  - Post an errand
  - Cancel before acceptance
  - Verify cancellation works
  - Check cancellation restrictions (if any)

#### 5. Transportation Services
- [ ] **Browse Transportation Services**
  - Navigate to transportation section
  - View available services
  - Filter by type (Shuttle, Point-to-Point, Bus)
  
- [ ] **Book Transportation**
  - Select a service
  - Fill in booking details
  - Submit booking
  - Verify booking appears in orders

#### 6. Notifications
- [ ] **Receive Notifications**
  - Post an errand
  - Verify notification when runner accepts
  - Check notification when runner starts
  - Verify notification when runner completes
  - Test notification permissions

---

### Testing as Business User

#### 1. Registration & Setup
- [ ] **Sign Up as Business**
  - Select "Business" as user type
  - Complete registration
  - Verify business-specific features available

#### 2. Business-Specific Features
- [ ] **Post Business Errands**
  - Create errands with business context
  - Verify business information displays
  - Test bulk errand posting

- [ ] **Contract Bookings**
  - Navigate to contract booking section
  - Create recurring service booking
  - Verify contract terms display
  - Test contract management

#### 3. All Individual User Tests
- [ ] Complete all tests from Individual User section
- [ ] Verify business features work alongside individual features

---

### Testing as Runner User

#### 1. Registration & Verification
- [ ] **Sign Up as Runner**
  - Select "Runner" as user type
  - Complete registration
  - Navigate to verification application
  
- [ ] **Submit Verification Application**
  - Fill in personal information
  - Upload required documents
  - Indicate if you have a vehicle
  - Upload vehicle documents (if applicable)
  - Submit application
  - Verify application status shows "Pending"

- [ ] **Wait for Admin Approval**
  - Check application status
  - Verify cannot browse errands until verified
  - Wait for admin to approve (or test with admin account)

#### 2. Runner Dashboard
- [ ] **View Home Page**
  - Log in as verified runner
  - Verify dashboard displays:
    - Greeting with name
    - Quick actions (Wallet, Browse Errands, My Orders)
    - Analytics (Success Rate, Avg Earnings, Active Jobs, Total Earned)
    - Unread message count (if any)

- [ ] **View Analytics**
  - Check success rate calculation
  - Verify average earnings display
  - Check active jobs count
  - Verify total earnings accuracy

#### 3. Browse Available Errands
- [ ] **View Available Errands**
  - Navigate to "Browse Errands" tab
  - Verify only "Posted" errands appear
  - Check errands already accepted by others don't appear
  
- [ ] **Filter Errands**
  - Filter by category (Grocery, Delivery, etc.)
  - Filter by vehicle requirement
  - Search by keyword
  - Verify filters work correctly

- [ ] **View Errand Details**
  - Click on an errand card
  - Verify all details display:
    - Title, description, category
    - Price, time limit
    - Pickup/delivery locations
    - Customer contact info
    - Special instructions
    - Images (if any)

- [ ] **Vehicle Requirement Filtering**
  - If runner has no vehicle: Verify errands requiring vehicles don't appear
  - If runner has vehicle: Verify all errands appear
  - Test accepting errand without vehicle (should fail if vehicle required)

#### 4. Accept Errands
- [ ] **Accept Errand (Within Limits)**
  - Find available errand
  - Click "Accept" button
  - Verify acceptance confirmation
  - Check errand moves to "My Orders"
  - Verify status changes to "Accepted"
  - Check customer receives notification

- [ ] **Accept Errand (Limit Reached)**
  - Accept 3 errands (max limit)
  - Try to accept 4th errand
  - Verify error message appears
  - Check limit indicator shows "3/3"

- [ ] **Accept Errand with Vehicle Requirement**
  - As runner without vehicle: Try to accept errand requiring vehicle
  - Verify error message
  - As runner with vehicle: Accept and verify success

#### 5. Manage Accepted Errands
- [ ] **View My Orders**
  - Navigate to "My Orders" tab
  - Verify accepted errands appear
  - Filter by status (All, Accepted, In Progress, Completed)
  - Check errand details display correctly

- [ ] **Start Errand**
  - Find errand with "Accepted" status
  - Click "Start Errand" button
  - Confirm action
  - Verify status changes to "In Progress"
  - Check customer receives notification
  - Verify chat becomes available

- [ ] **Complete Errand**
  - Find errand with "In Progress" status
  - Click "Complete Errand" button
  - Confirm action
  - Verify status changes to "Completed"
  - Check customer receives notification
  - Verify earnings added to wallet
  - Check chat closes automatically

- [ ] **Cancel Errand**
  - Find accepted or in-progress errand
  - Click "Cancel" button
  - Confirm cancellation
  - Verify errand returns to "Posted" status
  - Check errand appears in available errands again
  - Verify limit count decreases

#### 6. Communication
- [ ] **Chat with Customer**
  - Open accepted errand
  - Click "Chat" button
  - Send messages
  - Verify real-time message delivery
  - Check message history
  - Verify chat closes when errand completes

- [ ] **View Admin Messages**
  - Navigate to messages icon (top right)
  - View admin messages
  - Check unread count badge
  - Mark messages as read
  - Reply to admin messages (if enabled)

#### 7. Wallet & Earnings
- [ ] **View Wallet**
  - Navigate to "My Wallet"
  - Verify total balance displays
  - Check transaction history
  - Verify earnings from completed errands

- [ ] **Track Earnings**
  - Complete an errand
  - Verify earnings added to wallet
  - Check analytics update
  - Verify total earned increases

#### 8. Transportation Bookings (Runner)
- [ ] **Accept Transportation Bookings**
  - Navigate to transportation section
  - View available bookings
  - Accept booking (if applicable)
  - Verify booking appears in "My Orders"
  - Check limit enforcement (max 3 active bookings)

- [ ] **Manage Transportation Bookings**
  - Start transportation booking
  - Complete transportation booking
  - Cancel transportation booking
  - Verify limit updates correctly

#### 9. Runner Limits
- [ ] **Test Errand Limits**
  - Accept 3 errands
  - Verify cannot accept 4th
  - Complete 1 errand
  - Verify can now accept another
  - Check limit indicator updates

- [ ] **Test Transportation Limits**
  - Accept 3 transportation bookings
  - Verify cannot accept 4th
  - Complete 1 booking
  - Verify can now accept another

---

### Testing as Admin User

#### 1. Admin Authentication
- [ ] **Admin Login**
  - Log in with admin credentials
  - Verify redirect to admin dashboard
  - Check admin navigation appears

#### 2. Admin Dashboard (Home)
- [ ] **View Dashboard Overview**
  - Check quick stats display:
    - Total users
    - Total errands
    - Total revenue
    - Active runners
  - Verify real-time data updates
  - Test refresh functionality

#### 3. User Management
- [ ] **View All Users**
  - Navigate to "User Management"
  - Verify all users display
  - Check user types (Individual, Business, Runner, Admin)
  
- [ ] **Search Users**
  - Search by name
  - Search by email
  - Verify search results accurate

- [ ] **Filter Users**
  - Filter by user type
  - Filter by verification status
  - Verify filters work correctly

- [ ] **View User Details**
  - Click on user card
  - Verify full profile information
  - Check errand history
  - View verification status

- [ ] **Manage Users**
  - Deactivate user (if feature available)
  - Update user role (if feature available)
  - Verify changes persist

#### 4. Errand Oversight
- [ ] **View All Errands**
  - Navigate to "Errand Oversight"
  - Verify all errands display
  - Check errand statuses

- [ ] **Filter Errands**
  - Filter by status (Posted, Accepted, In Progress, Completed, Cancelled)
  - Filter by category
  - Search by keyword
  - Verify filters work

- [ ] **View Errand Details**
  - Click on errand
  - Verify complete information:
    - Customer details
    - Runner details (if assigned)
    - Status history
    - Payment information
    - Chat history (if accessible)

- [ ] **Monitor Errand Activity**
  - Watch real-time status changes
  - Verify notifications sent correctly
  - Check completion rates

#### 5. Payment Tracking
- [ ] **View Transactions**
  - Navigate to "Payment Tracking"
  - Verify all transactions display
  - Check payment statuses
  - Filter by status (Pending, Completed, Failed, Refunded)

- [ ] **View Revenue Analytics**
  - Check total revenue
  - View revenue by period
  - Verify commission calculations
  - Check runner earnings breakdown

- [ ] **Process Refunds**
  - Find transaction eligible for refund
  - Process refund
  - Verify refund status updates
  - Check customer notification

#### 6. Runner Verification
- [ ] **View Verification Queue**
  - Navigate to "Runner Verification"
  - Verify pending applications display
  - Check application details

- [ ] **Review Application**
  - Click on application
  - View submitted documents
  - Check personal information
  - Review vehicle documentation (if applicable)

- [ ] **Approve Runner**
  - Review application
  - Click "Approve"
  - Add notes (optional)
  - Verify runner status updates to "Verified"
  - Check runner receives notification
  - Verify runner can now browse errands

- [ ] **Reject Runner**
  - Review application
  - Click "Reject"
  - Add rejection reason
  - Verify runner status updates
  - Check runner receives notification

#### 7. Analytics Dashboard
- [ ] **View Platform Metrics**
  - Navigate to "Analytics"
  - Verify key metrics display:
    - Total users count
    - Active runners count
    - Total errands posted
    - Completion rate
    - Total revenue
    - Average earnings per runner

- [ ] **View Charts & Graphs**
  - Check data visualization
  - Verify chart accuracy
  - Test different time periods

- [ ] **Top Performers**
  - View top earning runners
  - Check completion rates
  - Verify data accuracy

#### 8. Provider Accounting
- [ ] **View Provider Accounting**
  - Navigate to provider accounting section
  - View company overview
  - Check runner earnings breakdown
  - Verify commission calculations

- [ ] **View Runner Details**
  - Click on runner
  - View detailed bookings
  - Check commission per booking
  - Verify total earnings

#### 9. Admin Messaging
- [ ] **Send Messages to Runners**
  - Navigate to messaging section
  - Compose message
  - Select runner(s)
  - Send message
  - Verify runner receives notification
  - Check unread count updates

- [ ] **View Message History**
  - Check sent messages
  - View replies from runners
  - Verify message threading

#### 10. Transportation Management
- [ ] **View Transportation Services**
  - Navigate to transportation management
  - View all services
  - Check service statuses

- [ ] **Manage Bookings**
  - View all transportation bookings
  - Filter by status
  - Check booking details
  - Monitor booking activity

---

## Quick Test Checklist

### Critical Path Tests (Must Test for Each User Type)

#### Individual/Business User Critical Tests
1. ✅ Sign up and login
2. ✅ Post an errand with all details
3. ✅ View posted errand in "My Orders"
4. ✅ Receive notification when runner accepts
5. ✅ Chat with runner
6. ✅ Verify status updates (Accepted → In Progress → Completed)
7. ✅ Cancel an errand (before acceptance)

#### Runner User Critical Tests
1. ✅ Sign up and submit verification application
2. ✅ Browse available errands (after verification)
3. ✅ Accept an errand
4. ✅ Start accepted errand
5. ✅ Complete in-progress errand
6. ✅ Verify earnings added to wallet
7. ✅ Test limit enforcement (max 3 active errands)
8. ✅ Chat with customer

#### Admin User Critical Tests
1. ✅ Login to admin dashboard
2. ✅ View all users
3. ✅ Approve/reject runner application
4. ✅ View all errands
5. ✅ View payment transactions
6. ✅ Send message to runner
7. ✅ View analytics dashboard

### Integration Tests
- [ ] **End-to-End Errand Flow**
  1. Individual posts errand
  2. Runner browses and accepts
  3. Runner starts errand
  4. Runner completes errand
  5. Payment processed
  6. Both parties can view completed status

- [ ] **Verification Flow**
  1. Runner signs up
  2. Runner submits application
  3. Admin reviews application
  4. Admin approves
  5. Runner can now browse errands

- [ ] **Chat Integration**
  1. Runner accepts errand
  2. Chat automatically created
  3. Both parties can send messages
  4. Chat closes when errand completes

### Edge Cases to Test
- [ ] Runner tries to accept errand when limit reached
- [ ] Runner without vehicle tries to accept errand requiring vehicle
- [ ] Customer cancels errand after acceptance
- [ ] Runner cancels accepted errand
- [ ] Multiple runners try to accept same errand simultaneously
- [ ] Network disconnection during critical operations
- [ ] Invalid data submission
- [ ] Permission denied scenarios (location, camera, etc.)

### Performance Tests
- [ ] Load time for dashboard
- [ ] Real-time notification delivery speed
- [ ] Chat message delivery speed
- [ ] Image upload performance
- [ ] Search/filter response time
- [ ] Large list rendering (100+ errands)

### Security Tests
- [ ] Users can only see their own data
- [ ] Runners cannot see errands accepted by others
- [ ] Admin-only features are protected
- [ ] Unverified runners cannot browse errands
- [ ] Payment information is secure
- [ ] File uploads are validated

---

## Test Environment Setup

### Prerequisites
1. **Test Accounts**: Create test accounts for each user type
   - Individual user account
   - Business user account
   - Runner account (verified and unverified)
   - Admin account

2. **Test Data**: Prepare test data
   - Sample errands in different categories
   - Test images for upload
   - Sample transportation services

3. **Device Testing**: Test on multiple devices
   - Android phone
   - iOS phone (if applicable)
   - Tablet
   - Web browser (if applicable)

### Test Execution Order
1. **Phase 1**: Individual User Tests
2. **Phase 2**: Business User Tests
3. **Phase 3**: Runner User Tests (unverified → verified)
4. **Phase 4**: Admin User Tests
5. **Phase 5**: Integration Tests
6. **Phase 6**: Edge Cases & Performance

---

## Notes for Testers

- **Real-time Features**: Some features require real-time updates. Wait a few seconds between actions to verify updates.
- **Notifications**: Ensure notification permissions are granted for accurate testing.
- **Location Services**: Location-based features require location permissions.
- **Network**: Test both online and offline scenarios.
- **Data Persistence**: Verify data persists after app restart.
- **Error Handling**: Test error scenarios (network errors, invalid input, etc.).

---

## Reporting Issues

When reporting bugs or issues, include:
1. User type tested
2. Steps to reproduce
3. Expected behavior
4. Actual behavior
5. Device/platform information
6. Screenshots/videos (if applicable)
7. Error messages (if any)

---

**Last Updated**: [Current Date]
**Version**: 1.0.0











