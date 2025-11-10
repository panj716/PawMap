# 🔥 Firebase Setup Instructions for PawMap

## Step 1: Create Firebase Project

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Click "Create a project" or "Add project"

2. **Project Configuration**
   - Project name: `PawMap` or `PawMap-iOS`
   - Enable Google Analytics: ✅ (Recommended)
   - Analytics account: Create new or use existing

3. **Project Settings**
   - Note your Project ID (you'll need this later)
   - Go to Project Settings (gear icon)

## Step 2: Add iOS App to Firebase

1. **Add iOS App**
   - Click "Add app" → iOS icon
   - iOS bundle ID: `com.yourcompany.PawMap` (or your actual bundle ID)
   - App nickname: `PawMap iOS`
   - App Store ID: (leave blank for now)

2. **Download Configuration File**
   - Download `GoogleService-Info.plist`
   - **Important**: Replace the placeholder file in your project with the real one

3. **Add to Xcode**
   - Drag `GoogleService-Info.plist` into your Xcode project
   - Make sure "Add to target" is checked for PawMap
   - Verify it appears in your app bundle

## Step 3: Enable Firebase Services

### 3.1 Authentication
1. Go to "Authentication" → "Sign-in method"
2. Enable the following providers:
   - ✅ Email/Password
   - ✅ Google (optional)
   - ✅ Apple (optional)

### 3.2 Firestore Database
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (we'll update rules later)
4. Select a location (choose closest to your users)

### 3.3 Storage
1. Go to "Storage"
2. Click "Get started"
3. Choose "Start in test mode"
4. Select same location as Firestore

### 3.4 Analytics (Optional)
1. Go to "Analytics" → "Events"
2. Enable automatic collection
3. Set up custom events (optional)

## Step 4: Update Xcode Project

### 4.1 Add Firebase SDK
1. In Xcode, go to File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: "Up to Next Major Version" with "10.0.0"
4. Add these products to your target:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics (optional)

### 4.2 Update Info.plist
Add these permissions to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PawMap needs location access to show nearby dog-friendly places</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>PawMap needs location access to show nearby dog-friendly places</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>PawMap needs photo access to let you add photos of dog-friendly places</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>PawMap needs photo access to let you add photos of dog-friendly places</string>
```

## Step 5: Deploy Security Rules

### 5.1 Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 5.2 Login to Firebase
```bash
firebase login
```

### 5.3 Initialize Firebase in Project
```bash
cd /path/to/your/PawMap/project
firebase init
```

Select these services:
- ✅ Firestore
- ✅ Storage
- ✅ Functions (optional)

### 5.4 Deploy Rules
```bash
firebase deploy --only firestore:rules,storage:rules
```

## Step 6: Update GoogleService-Info.plist

Replace the placeholder values in `GoogleService-Info.plist` with your actual Firebase project values:

1. Open the downloaded `GoogleService-Info.plist` from Firebase Console
2. Copy the values to your project's `GoogleService-Info.plist`
3. Verify all keys are correctly set

## Step 7: Test Firebase Connection

### 7.1 Update App Delegate
```swift
import FirebaseCore

@main
struct PawMapApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 7.2 Test Basic Connection
Add this to test Firebase connection:
```swift
import FirebaseFirestore

// Test Firestore connection
let db = Firestore.firestore()
print("Firestore initialized: \(db.app.name)")
```

## Step 8: Create Admin User (Optional)

If you want to create an admin user for content moderation:

1. Go to Firestore Database
2. Create a new document in `admins` collection
3. Document ID: Your user ID
4. Fields:
   - `isAdmin: true`
   - `email: your-email@example.com`
   - `createdAt: timestamp`

## Step 9: Verify Setup

### 9.1 Check Firebase Console
- Authentication: Should show your project
- Firestore: Should show empty database
- Storage: Should show empty bucket

### 9.2 Test in App
- Build and run your app
- Check Xcode console for Firebase initialization messages
- Verify no Firebase-related errors

## Troubleshooting

### Common Issues:

1. **"Firebase not configured" error**
   - Ensure `GoogleService-Info.plist` is in your app bundle
   - Check that `FirebaseApp.configure()` is called in `init()`

2. **Bundle ID mismatch**
   - Verify bundle ID in Firebase Console matches your Xcode project
   - Update bundle ID in Firebase Console if needed

3. **Permission denied errors**
   - Check Firestore rules are deployed
   - Verify user is authenticated before accessing protected data

4. **Build errors**
   - Clean build folder (Cmd+Shift+K)
   - Delete derived data
   - Rebuild project

## Next Steps

Once Firebase is set up:

1. ✅ Run the app to test basic Firebase connection
2. ✅ Implement authentication flow
3. ✅ Migrate existing data to Firestore
4. ✅ Test real-time updates
5. ✅ Deploy to production

## Support

- Firebase Documentation: https://firebase.google.com/docs
- iOS SDK Guide: https://firebase.google.com/docs/ios/setup
- Firestore Rules: https://firebase.google.com/docs/firestore/security/get-started

