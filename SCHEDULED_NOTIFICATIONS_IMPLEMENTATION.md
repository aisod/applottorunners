# Scheduled Notifications Implementation

## Overview
I've implemented comprehensive scheduled notification systems for contract bookings and bus bookings, following the same pattern as the existing errand notifications. The system provides timely reminders at multiple intervals: 5 minutes before, 10 minutes before, 1 hour before, at start time, and daily reminders for long-term bookings.

## New Services Created

### 1. ScheduledContractNotificationService
**File:** `lib/services/scheduled_contract_notification_service.dart`

**Features:**
- Monitors contract bookings using `contract_start_date` and `contract_start_time`
- Sends notifications at multiple intervals:
  - **5 minutes before:** "Contract service starts in 5 minutes!"
  - **10 minutes before:** "Contract service starting soon!"
  - **1 hour before:** "Contract reminder - 1 hour"
  - **At start time:** "Your contract service has started!"
  - **Daily reminders:** For contracts scheduled days in advance
- Prevents duplicate notifications using database flags
- Stores notifications in the database for persistence
- Includes contract duration information in daily reminders

**Key Methods:**
- `initialize()` - Starts the service
- `_checkScheduledContracts()` - Main checking loop (runs every 5 minutes)
- `_checkContractReminders()` - Processes individual contracts
- `getUpcomingScheduledContracts()` - Retrieves upcoming contracts for a user

### 2. ScheduledBusNotificationService
**File:** `lib/services/scheduled_bus_notification_service.dart`

**Features:**
- Monitors bus bookings using `booking_date` and `booking_time`
- Sends notifications at multiple intervals:
  - **5 minutes before:** "Bus service starts in 5 minutes!"
  - **10 minutes before:** "Bus service starting soon!"
  - **1 hour before:** "Bus service reminder - 1 hour"
  - **At start time:** "Your bus service has started!"
  - **Daily reminders:** For bus bookings scheduled days in advance
- Includes route information (pickup to dropoff) in notifications
- Prevents duplicate notifications using database flags
- Stores notifications in the database for persistence

**Key Methods:**
- `initialize()` - Starts the service
- `_checkScheduledBusBookings()` - Main checking loop (runs every 5 minutes)
- `_checkBusBookingReminders()` - Processes individual bus bookings
- `getUpcomingScheduledBusBookings()` - Retrieves upcoming bus bookings for a user

## Enhanced NotificationService
**File:** `lib/services/notification_service.dart`

**New Methods Added:**
- `notifyContractBookingConfirmed()` - Contract booking confirmation
- `notifyContractBookingStarted()` - Contract service started
- `notifyContractBookingCompleted()` - Contract service completed
- `notifyContractBookingCancelled()` - Contract booking cancelled
- `notifyBusBookingConfirmed()` - Bus booking confirmation
- `notifyBusBookingStarted()` - Bus service started
- `notifyBusBookingCompleted()` - Bus service completed
- `notifyBusBookingCancelled()` - Bus booking cancelled
- `notifyBusBookingNoShow()` - Bus service no-show notification

## Database Schema Updates
**File:** `add_notification_columns.sql`

**Contract Bookings Table (`contract_bookings`):**
- `notification_5min_sent` - Boolean flag for 5-minute reminder
- `notification_10min_sent` - Boolean flag for 10-minute reminder
- `notification_1hour_sent` - Boolean flag for 1-hour reminder
- `notification_start_sent` - Boolean flag for start time notification
- `notification_daily_sent` - Array of dates for daily reminders

**Bus Service Bookings Table (`bus_service_bookings`):**
- `notification_5min_sent` - Boolean flag for 5-minute reminder
- `notification_10min_sent` - Boolean flag for 10-minute reminder
- `notification_1hour_sent` - Boolean flag for 1-hour reminder
- `notification_start_sent` - Boolean flag for start time notification
- `notification_daily_sent` - Array of dates for daily reminders

**Notifications Table (`notifications`):**
- `contract_booking_id` - Foreign key reference to contract bookings
- `bus_booking_id` - Foreign key reference to bus service bookings

## App Integration
**File:** `lib/main.dart`

**Changes Made:**
- Added imports for new notification services
- Initialized `ScheduledContractNotificationService` when user is authenticated
- Initialized `ScheduledBusNotificationService` when user is authenticated
- Services start automatically when user logs in

## Notification Timing Logic

### Contract Bookings
- Uses `contract_start_date` (DATE) + `contract_start_time` (TIME) to calculate exact start time
- Combines date and time to create precise DateTime for scheduling
- Includes contract duration information in daily reminders

### Bus Bookings
- Uses `booking_date` (DATE) + `booking_time` (TIME) to calculate exact start time
- Includes route information (pickup to dropoff) in all notifications
- Provides clear location guidance for users

## Key Features

### 1. Duplicate Prevention
- Each notification type has a corresponding database flag
- Daily reminders use an array to track which dates have been notified
- Prevents spam notifications for the same event

### 2. Comprehensive Coverage
- **Immediate:** 5-minute and 10-minute warnings
- **Short-term:** 1-hour advance notice
- **Real-time:** Start time notifications
- **Long-term:** Daily reminders for future bookings

### 3. User Experience
- Clear, actionable notification messages
- Includes relevant context (locations, service names, durations)
- Consistent with existing errand notification patterns
- Proper error handling and logging

### 4. Database Integration
- All notifications stored in database for persistence
- Proper foreign key relationships
- Indexed for performance
- RLS-compliant for security

## Usage Examples

### Contract Booking Notifications
```
5 minutes before: "Contract service starts in 5 minutes! Daily office commute is about to begin. Please be ready."
1 hour before: "Contract reminder - 1 hour. Daily office commute will start in 1 hour. Please prepare."
At start: "Your contract service has started! Daily office commute is now active. Your transportation service is beginning."
Daily: "Contract booking reminder. Daily office commute will start in 2 days. Duration: 1 month. Status: CONFIRMED"
```

### Bus Booking Notifications
```
5 minutes before: "Bus service starts in 5 minutes! Lagos-Abuja Express is about to begin. Please head to Victoria Island Terminal."
1 hour before: "Bus service reminder - 1 hour. Lagos-Abuja Express will start in 1 hour. Route: Victoria Island Terminal to Abuja Central Station"
At start: "Your bus service has started! Lagos-Abuja Express is now active. Please proceed to Victoria Island Terminal."
Daily: "Bus booking reminder. Lagos-Abuja Express will start in 1 day. Route: Victoria Island Terminal to Abuja Central Station. Status: CONFIRMED"
```

## Next Steps

1. **Run Database Migration:** Execute `add_notification_columns.sql` to add notification tracking columns
2. **Test Notifications:** Create test contract and bus bookings to verify notification timing
3. **Monitor Performance:** Check that the 5-minute polling doesn't impact app performance
4. **User Feedback:** Collect feedback on notification timing and content

## Technical Notes

- Services use singleton pattern for consistent state management
- Timer-based polling every 5 minutes (same as errand notifications)
- Proper disposal methods to prevent memory leaks
- Comprehensive error handling and logging
- Follows existing code patterns and conventions
- Compatible with existing notification infrastructure
