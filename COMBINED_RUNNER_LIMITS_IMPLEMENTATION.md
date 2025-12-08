## UI Updates

#### Runner Dashboard (`lib/pages/runner_dashboard_page.dart`)
- Updated error messages to reflect new limit and completion requirement
- Modified limit validation logic
- Enhanced user feedback for limit restrictions
- **New Combined Limit Display**: Added prominent display of total active jobs (X/2)
- **Visual Progress Indicator**: Progress bar showing current usage of the 2-job limit
- **Color-coded Status**: Red when limit reached, blue when available
- **Clear Messaging**: Updated info text to explain the 2-job limit system

#### Available Errands Page (`lib/pages/available_errands_page.dart`)
- Updated errand acceptance error messages
- Added transportation booking limit validation
- Consistent error messaging across both job types
- **Stats Display**: Shows current active jobs (X/2) in the app bar stats
- **Real-time Updates**: Refreshes limit information after accepting jobs

#### Browse Errands Page (`lib/pages/browse_errands_page.dart`)
- Updated error messages to reflect new limit and completion requirement
- Maintained existing validation logic with new messaging
