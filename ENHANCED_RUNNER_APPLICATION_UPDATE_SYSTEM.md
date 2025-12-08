# Enhanced Runner Application Update System

## Overview
This update enhances the runner application system to include all required document fields when updating vehicle information, adds verification warnings, and prevents unverified runners from accepting errands.

## Key Features Implemented

### 1. **Complete Document Upload System**
- **Code of Conduct Agreement**: Required for all runners
- **Driver License**: Required for vehicle owners
- **Vehicle Photos**: Multiple photo upload with preview
- **License Disc Photos**: Multiple photo upload with preview
- **Document Validation**: Ensures all required documents are uploaded

### 2. **Verification Status Warning**
- **Warning Message**: Shows orange warning box for verified runners
- **Clear Explanation**: Explains that updating will change status to "Pending"
- **No Errand Notifications**: Warns that they won't receive errands until re-verified

### 3. **Automatic Verification Reset**
- **Status Change**: Updates verification status to "pending" when application is updated
- **User Table Sync**: Sets `is_verified = false` in users table
- **Application Table Sync**: Sets `verification_status = 'pending'` in runner_applications table

### 4. **Errand Acceptance Prevention**
- **Verification Check**: Added `canRunnerAcceptErrands()` method
- **Errand Acceptance**: Prevents unverified runners from accepting errands
- **Transportation Booking**: Prevents unverified runners from accepting transportation bookings
- **Clear Error Messages**: Explains why they can't accept jobs

## Technical Implementation

### **Profile Page Updates** (`lib/pages/profile_page.dart`)

#### Enhanced Update Dialog
- **Warning Section**: Orange warning box for verified runners
- **Document Sections**: Complete document upload interface
- **Validation**: Comprehensive validation for all fields
- **User Experience**: Clear feedback and error messages

#### New Methods Added
- `_buildDocumentUploadSection()`: Handles single document uploads
- `_buildMultipleImageUploadSection()`: Handles multiple photo uploads
- `_uploadDocument()`: Uploads PDF documents
- `_uploadImages()`: Uploads multiple images
- `_updateRunnerApplicationWithDocuments()`: Updates application with documents

#### Key Features
```dart
// Warning for verified runners
if (isCurrentlyVerified) {
  // Shows orange warning box
  // Explains verification status change
  // Warns about errand notification loss
}

// Document validation
if (codeOfConductPdf == null || codeOfConductPdf!.isEmpty) {
  // Shows error message
  // Prevents form submission
}

// Status reset
'verification_status': 'pending', // Always set to pending
'is_verified': false, // Always set to false
```

### **SupabaseConfig Updates** (`lib/supabase/supabase_config.dart`)

#### New Methods Added
- `canRunnerAcceptErrands(String userId)`: Checks if runner can accept errands
- `getVerifiedRunners()`: Gets list of verified runners

#### Enhanced Existing Methods
- `acceptErrand()`: Added verification check before acceptance
- `updateTransportationBooking()`: Added verification check for transportation bookings

#### Verification Logic
```dart
// Check verification before errand acceptance
final canAccept = await canRunnerAcceptErrands(runnerId);
if (!canAccept) {
  throw Exception('Cannot accept errand. You must be verified to accept errands.');
}

// Check verification before transportation booking acceptance
if (isAcceptance) {
  final canAccept = await canRunnerAcceptErrands(driverId);
  if (!canAccept) {
    throw Exception('Cannot accept transportation booking. You must be verified.');
  }
}
```

## User Experience Flow

### **For Verified Runners Updating Application**
1. **Click "Update Application"** → Shows enhanced dialog
2. **See Warning Message** → Orange box explains verification status change
3. **Update Vehicle Info** → Fill in vehicle details
4. **Upload Documents** → Upload all required documents
5. **Submit Application** → Status changes to "Pending"
6. **Receive Confirmation** → Orange message explains status change
7. **Cannot Accept Errands** → Until re-verified by admin

### **For Unverified Runners Trying to Accept Errands**
1. **Click "Accept Errand"** → System checks verification
2. **Verification Check Fails** → Shows error message
3. **Clear Explanation** → "You must be verified to accept errands"
4. **Redirected to Profile** → To complete verification process

## Document Upload Features

### **Single Document Upload**
- **PDF Support**: Driver license, code of conduct
- **Upload Button**: Easy file selection
- **Status Display**: Shows "Document uploaded" with green checkmark
- **Remove Option**: Can remove and re-upload documents

### **Multiple Image Upload**
- **Photo Preview**: Shows uploaded photos in grid
- **Add More**: Can add additional photos
- **Remove Individual**: Can remove specific photos
- **Count Display**: Shows number of uploaded photos

### **Validation System**
- **Required Fields**: All required documents must be uploaded
- **Error Messages**: Clear validation messages
- **Form Prevention**: Cannot submit without required documents

## Security and Data Integrity

### **Verification Status Management**
- **Atomic Updates**: Both tables updated together
- **Status Consistency**: Maintains consistency between tables
- **Audit Trail**: Updates tracked with timestamps

### **Access Control**
- **Verified Runners Only**: Only verified runners can accept jobs
- **Admin Verification**: Only admins can verify runners
- **Document Security**: Documents stored securely in Supabase

## Error Handling

### **User-Friendly Messages**
- **Verification Errors**: Clear explanation of verification requirements
- **Document Errors**: Specific error messages for missing documents
- **Upload Errors**: Detailed error messages for upload failures

### **Fallback Mechanisms**
- **Graceful Degradation**: System continues to work if some features fail
- **Error Recovery**: Users can retry failed operations
- **Status Recovery**: System maintains consistent state

## Testing Scenarios

### **Verified Runner Updates Application**
1. ✅ Warning message appears
2. ✅ All document fields are present
3. ✅ Validation works correctly
4. ✅ Status changes to pending
5. ✅ Cannot accept errands after update

### **Unverified Runner Tries to Accept Errand**
1. ✅ Verification check runs
2. ✅ Error message appears
3. ✅ Cannot accept errand
4. ✅ Redirected to complete verification

### **Document Upload System**
1. ✅ Single document upload works
2. ✅ Multiple image upload works
3. ✅ Document validation works
4. ✅ Remove/replace documents works

## Deployment Requirements

### **Dependencies**
No new dependencies required - uses existing:
- `ImageUpload` class for file uploads
- Existing Supabase client
- Existing UI components

### **Database Changes**
No database schema changes required - uses existing:
- `runner_applications` table
- `users` table
- Existing document fields

### **Configuration**
No additional configuration required - uses existing:
- Supabase configuration
- File upload settings
- RLS policies

## Benefits

### **For Runners**
- **Complete Control**: Can update all application details
- **Clear Warnings**: Understand consequences of updates
- **Document Management**: Easy document upload and management
- **Status Transparency**: Clear understanding of verification status

### **For Admins**
- **Complete Applications**: All required documents included
- **Verification Control**: Can verify/reject updated applications
- **Document Access**: Can download and review all documents
- **Status Management**: Clear verification status tracking

### **For System**
- **Data Integrity**: Consistent verification status across tables
- **Security**: Only verified runners can accept jobs
- **User Experience**: Clear feedback and error messages
- **Maintainability**: Well-structured code with clear separation of concerns

This enhanced system provides a complete solution for runner application updates while maintaining security and data integrity throughout the process.
