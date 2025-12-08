# TODO List

## Completed Tasks ✅

### Database Schema Fixes
- [x] Fix database schema mismatch in delivery form - remove non-existent fields
- [x] Fix database schema mismatch in shopping form - clean up imports
- [x] Add vehicle_type column to errands table and update forms to use it
- [x] Fix database field errors in elderly services form
- [x] Fix database field errors in document services form
- [x] Update document services constraint to allow more service types
- [x] Add missing started_at column to errands table
- [x] Add location coordinate fields to errands table

### Form Updates
- [x] Add vehicle type dropdown to delivery form page
- [x] Add vehicle type dropdown to errands form page
- [x] Add vehicle type dropdown to shopping form page
- [x] Add vehicle type dropdown to enhanced post errand form page
- [x] Remove applicant information fields from registration form
- [x] Remove Low Priority option from priority level selection
- [x] Add pickup and delivery location fields as optional to enhanced post errand form
- [x] Remove Low Priority option from special orders page (enhanced post errand form)
- [x] Add pickup and delivery location fields as optional to special orders page
- [x] Fix budget column issue in enhanced post errand form by storing budget in special_instructions
- [x] Fix priority column issue in enhanced post errand form by storing priority in special_instructions

### Feature Additions
- [x] Add pickup documents field and optional PDF upload to document services form
- [x] Make pickup documents field optional in document services form
- [x] Fix PDF upload in license discs form to match document services implementation
- [x] Make pickup documents optional and delivery documents required in registration form

## Pending Tasks 🔄

### High Priority
- [ ] Test all form submissions to ensure database compatibility
- [ ] Verify location coordinate fields are working correctly
- [ ] Test PDF upload functionality across all forms

### Medium Priority
- [ ] Add comprehensive error handling for database operations
- [ ] Implement form validation for location coordinates
- [ ] Add loading states for image/PDF uploads

### Low Priority
- [ ] Optimize form performance for large image uploads
- [ ] Add form auto-save functionality
- [ ] Implement form templates for common service types

## Notes
- All forms now use the correct database schema
- Budget and priority information are stored in special_instructions JSONB field
- Vehicle type is stored in both vehicle_type column and special_instructions for reference
- Location coordinates are properly handled for pickup, delivery, and main service locations
- PDF uploads are standardized across document-related forms
- Price calculation correctly includes priority surcharge (+N$50 for urgent)
