# Firebase Setup Instructions for Dozzi

## Prerequisites

1. **Dozzi Backend** must be deployed first (see `/Users/shreyas/work/rnd/Dozzi-backend`)
2. **Firebase project** created via Terraform or Firebase Console
3. **Xcode 15+** with iOS 17+ deployment target

## Step 1: Add Firebase iOS SDK Dependencies

### Using Xcode Package Manager

1. Open `Taily.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter Firebase iOS SDK URL: `https://github.com/firebase/firebase-ios-sdk`
4. Select **Up to Next Major Version** (10.0.0 or later)
5. Add these packages to the **Dozzi** target:
   - ✅ `FirebaseAuth`
   - ✅ `FirebaseCore`
   - ✅ `FirebaseFirestore`
   - ✅ `GoogleSignIn-iOS` (separate package: `https://github.com/google/GoogleSignIn-iOS`)

### Alternative: Swift Package Manager

Add to `Package.swift` (if using SPM):

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.0.0") // Already added
]
```

## Step 2: Configure Firebase

### Download Configuration File

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Dozzi project (created by Terraform)
3. Go to **Project Settings** → **General**
4. Under **Your Apps**, add iOS app if not exists:
   - **Bundle ID**: `com.dozzi.bedtime-stories` (or your bundle ID)
   - **App Name**: `Dozzi`
5. Download `GoogleService-Info.plist`
6. **Replace** the template file at `Taily/GoogleService-Info.plist.template`
7. **Rename** to `GoogleService-Info.plist`
8. **Add to Xcode**: Drag into Xcode project, ensuring it's added to the Dozzi target

### Bundle Identifier Configuration

Ensure your Xcode project Bundle Identifier matches Firebase:
- Xcode: **Project → Dozzi → Signing & Capabilities → Bundle Identifier**
- Should match the bundle ID in Firebase console

## Step 3: Configure URL Schemes (For Google Sign In)

1. Open `GoogleService-Info.plist`
2. Copy the `REVERSED_CLIENT_ID` value
3. In Xcode, go to **Project → Dozzi → Info**
4. Add **URL Scheme**:
   - **Identifier**: `GoogleSignIn`
   - **URL Scheme**: Paste the `REVERSED_CLIENT_ID` value

Example:
```
URL Scheme: com.googleusercontent.apps.123456789-abcdefgh
```

## Step 4: Configure Apple Sign In

1. In Xcode, go to **Project → Dozzi → Signing & Capabilities**
2. Click **+ Capability**
3. Add **Sign in with Apple**
4. In Apple Developer Console:
   - Enable **Sign in with Apple** for your App ID
   - Configure **Sign in with Apple** for your app

## Step 5: Update Info.plist

Add these entries to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>REVERSED_CLIENT_ID_FROM_PLIST</string>
        </array>
    </dict>
</array>

<!-- For better Google Sign In experience -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlegmail</string>
    <string>googlemail</string>
    <string>googledrive</string>
    <string>googledocs</string>
    <string>googlesheets</string>
</array>
```

## Step 6: Test Authentication

### Build and Test

1. Build the project: `⌘ + B`
2. Run on device/simulator: `⌘ + R`
3. Test sign-in flows:
   - Tap **Sign In** button in overlay
   - Try **Apple Sign In**
   - Try **Google Sign In**

### Verify Backend Connection

The app should connect to:
- **Functions**: `https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/`
- **Firestore**: Automatic via Firebase SDK
- **Authentication**: Automatic via Firebase SDK

## Step 7: Configure Backend API Endpoints

Update app configuration to use your deployed backend:

1. Create `Taily/Config/APIConfig.swift`:

```swift
import Foundation

enum APIConfig {
    static let baseURL = "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net"
    
    static let endpoints = [
        "synthesizeSpeech": "\(baseURL)/synthesizeSpeech",
        "personalizedStory": "\(baseURL)/synthesizePersonalizedStory",
        "healthCheck": "\(baseURL)/healthCheck"
    ]
}
```

## Troubleshooting

### Common Issues

1. **"No such module 'FirebaseAuth'"**
   - Ensure Firebase packages are added to correct target
   - Clean build folder: `⌘ + Shift + K`

2. **Google Sign In not working**
   - Verify `REVERSED_CLIENT_ID` in URL schemes
   - Check bundle identifier matches Firebase

3. **Apple Sign In not working**
   - Ensure capability is added in Xcode
   - Verify App ID configuration in Apple Developer

4. **Firebase initialization fails**
   - Check `GoogleService-Info.plist` is in project bundle
   - Verify file is added to target membership

### Debug Authentication

```swift
// Add to AuthService for debugging
func debugAuth() {
    print("Firebase Auth configured:", Auth.auth().app?.options.projectID ?? "nil")
    print("Current user:", Auth.auth().currentUser?.uid ?? "nil")
}
```

## Security Notes

- ✅ `GoogleService-Info.plist` is safe to commit (contains public config)
- ❌ Never commit actual service account keys
- ✅ Firebase Security Rules protect backend data
- ✅ Authentication tokens are automatically managed

## Next Steps

After Firebase authentication is working:
1. Test TTS API calls with authenticated tokens
2. Configure Firestore for storing user data and stories
3. Test the complete story generation + TTS flow
4. Set up push notifications (optional)

## Support

- Firebase Documentation: https://firebase.google.com/docs/ios
- Google Sign In Documentation: https://developers.google.com/identity/sign-in/ios
- Apple Sign In Documentation: https://developer.apple.com/sign-in-with-apple/