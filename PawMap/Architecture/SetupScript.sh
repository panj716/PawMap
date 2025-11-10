#!/bin/bash

# PawMap Firebase Setup Script
# This script helps you set up Firebase for your PawMap project

echo "🔥 PawMap Firebase Setup Script"
echo "================================"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
    echo "✅ Firebase CLI installed"
else
    echo "✅ Firebase CLI already installed"
fi

# Check if user is logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please log in to Firebase:"
    firebase login
else
    echo "✅ Already logged in to Firebase"
fi

# Initialize Firebase in the project
echo "🚀 Initializing Firebase in your project..."
firebase init

echo ""
echo "📋 Next Steps:"
echo "1. Go to https://console.firebase.google.com"
echo "2. Create a new project called 'PawMap'"
echo "3. Add an iOS app with bundle ID: com.yourcompany.PawMap"
echo "4. Download GoogleService-Info.plist"
echo "5. Replace the placeholder file in your Xcode project"
echo "6. Enable Authentication, Firestore, and Storage in Firebase Console"
echo "7. Deploy the security rules: firebase deploy --only firestore:rules,storage:rules"
echo ""
echo "🎉 Setup complete! Follow the instructions in FirebaseSetupInstructions.md"

