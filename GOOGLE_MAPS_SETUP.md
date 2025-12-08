# Google Maps and Places API Setup

## Overview
The location picker functionality has been implemented and will work with basic geocoding even without a Google API key. However, for the best user experience with autocomplete suggestions, you'll need to set up Google Places API.

## ⚠️ SECURITY UPDATE
**Hardcoded API keys have been removed** from the codebase for security. You must now configure your API key properly.

## Current Status
✅ **Basic functionality works without API key**
- Manual address entry with geocoding
- Current location detection
- Map picker with draggable markers
- Basic place search using geocoding

🔧 **Enhanced functionality requires API key**
- Real-time autocomplete suggestions as you type
- Rich place details with business information
- Better search results for businesses and landmarks

## Setting up Google Places API (Required for Enhanced Features)

### 1. Get Google Cloud Platform API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable these APIs:
   - **Places API**
   - **Maps SDK for Android** (if building for Android)
   - **Maps SDK for iOS** (if building for iOS)
   - **Geocoding API**

### 2. Create API Key
1. Go to "Credentials" in the Google Cloud Console
2. Click "Create Credentials" → "API Key"
3. Copy the generated API key

### 3. Configure the API Key

#### Option A: Environment Variable (Recommended)
1. Set the environment variable when running Flutter:
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
```

#### Option B: Build Configuration
1. For production builds, add to your build configuration:
```bash
flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
flutter build ios --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
flutter build web --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
```

### 4. Platform-specific Configuration

#### For Android:
1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

#### For iOS:
1. Open `ios/Runner/AppDelegate.swift`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

#### For Web:
1. Open `web/index.html`
2. Replace both instances of `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
```html
<meta name="google_maps_api_key" content="YOUR_ACTUAL_API_KEY_HERE">
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY_HERE&libraries=places"></script>
```

### 5. Add Required Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to help you select pickup and delivery locations.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to help you select pickup and delivery locations.</string>
```

## Testing Without API Key
The app will work immediately without an API key! You can:
1. Type addresses manually (basic autocomplete using geocoding)
2. Use "Current Location" option
3. Select locations on the map
4. Get common Windhoek locations as suggestions

## Features Implemented

### Location Input Fields
- ✅ **Your Location** - Required field with validation
- ✅ **Pickup Location** - Optional field for item collection
- ✅ **Delivery Location** - Optional field for item delivery

### Autocomplete Functionality
- ✅ Real-time search as you type
- ✅ "Use Current Location" option
- ✅ GPS location detection
- ✅ Fallback suggestions for common locations

### Map Integration
- ✅ Interactive map picker
- ✅ Draggable location marker
- ✅ Address resolution from coordinates
- ✅ Visual location confirmation

### Data Storage
- ✅ Addresses stored as strings
- ✅ Coordinates stored for mapping (latitude/longitude)
- ✅ Integration with existing errand submission flow

## Troubleshooting

### "No locations found" when searching
- This happens without an API key for uncommon addresses
- Users can still use the map picker or current location
- Type more specific addresses (include city, street names)

### Location permission denied
- Guide users to enable location permissions in device settings
- The app gracefully handles permission denials

### Map doesn't load
- Check internet connection
- Ensure Google Maps API key is configured for your platform
- Check API key restrictions in Google Cloud Console

### API Key Security Issues
- Never commit API keys to version control
- Use environment variables or build-time configuration
- Restrict API key usage in Google Cloud Console

## Next Steps
1. **Test the current implementation** - it works without API key!
2. **Set up Google API key** when ready for enhanced features
3. **Test on real devices** for location permissions
4. **Consider adding location history** for frequently used addresses

## Security Best Practices
- ✅ API keys are no longer hardcoded in source code
- ✅ Use environment variables for sensitive configuration
- ✅ Restrict API key usage in Google Cloud Console
- ✅ Monitor API usage for unexpected activity
- ✅ Rotate API keys periodically

The location picker is now fully integrated into your errand posting flow and ready to use with improved security!
