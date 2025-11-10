# PawMap Firebase Architecture

## 📁 New Project Structure

```
PawMap/
├── Models/
│   ├── Place.swift (refactored)
│   ├── Review.swift (refactored)
│   ├── User.swift (new)
│   └── CuratedPlace.swift (existing)
│
├── ViewModels/
│   ├── PlaceViewModel.swift (new)
│   ├── ReviewViewModel.swift (new)
│   ├── AuthViewModel.swift (new)
│   ├── FavoritesViewModel.swift (new)
│   └── TopPicksViewModel.swift (new)
│
├── Services/
│   ├── FirebaseService.swift (new)
│   ├── StorageService.swift (new)
│   ├── AuthService.swift (new)
│   ├── LocationService.swift (refactored from LocationManager)
│   └── ImageCacheService.swift (new)
│
├── Views/
│   ├── Map/
│   │   ├── ModernMapView.swift (refactored)
│   │   └── PlaceAnnotationView.swift (extracted)
│   ├── Places/
│   │   ├── PlaceDetailView.swift (refactored)
│   │   ├── AddPlaceView.swift (refactored)
│   │   └── PlaceListView.swift (new)
│   ├── Reviews/
│   │   ├── ReviewListView.swift (refactored)
│   │   └── AddReviewView.swift (refactored)
│   ├── Profile/
│   │   ├── ProfileView.swift (refactored)
│   │   ├── LoginView.swift (refactored)
│   │   └── EditProfileView.swift (refactored)
│   ├── Favorites/
│   │   └── FavoritesView.swift (refactored)
│   └── TopPicks/
│       └── TopPicksView.swift (refactored)
│
├── Utils/
│   ├── ImageCache.swift (new)
│   ├── ErrorHandler.swift (new)
│   └── Extensions/
│       ├── Color+Extensions.swift
│       └── Date+Extensions.swift
│
├── Configuration/
│   ├── FirebaseConfig.swift (new)
│   └── AppConstants.swift (new)
│
└── Resources/
    ├── GoogleService-Info.plist
    └── Firestore.rules
```

## 🔄 Data Flow Architecture

```
SwiftUI Views → ViewModels → Services → Firebase
     ↑              ↑           ↑
   @State      @Published   Real-time
   @Binding    @StateObject   Updates
```

## 🗄️ Firestore Collections Structure

```
/places
  /{placeId}
    - name: string
    - type: string
    - address: string
    - coordinates: geopoint
    - rating: number
    - tags: array
    - notes: string
    - createdBy: string (userId)
    - createdAt: timestamp
    - updatedAt: timestamp
    - isVerified: boolean
    - images: array of strings (storage URLs)
    - dogAmenities: map
    - reportCount: number

/reviews
  /{reviewId}
    - placeId: string
    - userId: string
    - userName: string
    - rating: number
    - comment: string
    - images: array of strings
    - createdAt: timestamp
    - helpfulCount: number
    - helpfulVoters: array of userIds

/users
  /{userId}
    - email: string
    - name: string
    - profileImageUrl: string
    - dogName: string
    - dogBreed: string
    - dogBirthday: timestamp
    - dogWeight: number
    - dogGender: string
    - dogTraits: array
    - dogNotes: string
    - createdAt: timestamp
    - lastActiveAt: timestamp

/favorites
  /{userId}
    - placeIds: array of strings

/curatedPlaces
  /{placeId}
    - name: string
    - type: string
    - address: string
    - coordinates: geopoint
    - imageUrl: string
    - description: string
    - isNational: boolean
    - rating: number
    - tags: array
    - amenities: array
    - createdAt: timestamp

/reports
  /{reportId}
    - placeId: string
    - reporterId: string
    - reason: string
    - description: string
    - createdAt: timestamp
    - isResolved: boolean
```

## 🔐 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Places collection
    match /places/{placeId} {
      allow read: if true; // Anyone can read places
      allow create: if request.auth != null && 
                       request.auth.uid == resource.data.createdBy;
      allow update: if request.auth != null && 
                       (request.auth.uid == resource.data.createdBy || 
                        isAdmin(request.auth.uid));
      allow delete: if request.auth != null && isAdmin(request.auth.uid);
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
      allow delete: if request.auth != null && 
                       (request.auth.uid == resource.data.userId || 
                        isAdmin(request.auth.uid));
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
    
    // Favorites collection
    match /favorites/{userId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == userId;
    }
    
    // Curated places (admin only)
    match /curatedPlaces/{placeId} {
      allow read: if true;
      allow write: if request.auth != null && isAdmin(request.auth.uid);
    }
    
    // Reports
    match /reports/{reportId} {
      allow read: if request.auth != null && isAdmin(request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null && isAdmin(request.auth.uid);
    }
    
    // Helper function to check admin status
    function isAdmin(uid) {
      return get(/databases/$(database)/documents/admins/$(uid)).data.isAdmin == true;
    }
  }
}
```

## 🚀 Implementation Phases

### Phase 1: Firebase Setup & Basic Services
1. Add Firebase SDK to project
2. Create FirebaseService base class
3. Implement AuthService
4. Create StorageService for images

### Phase 2: Data Models & ViewModels
1. Refactor existing models for Firestore
2. Create ViewModels with Firebase integration
3. Implement real-time data binding

### Phase 3: Core Features Migration
1. Migrate Places management to Firestore
2. Implement Reviews system
3. Add Favorites with real-time sync

### Phase 4: Advanced Features
1. Implement Top Picks with Cloud Functions
2. Add content moderation
3. Implement reporting system

### Phase 5: Performance & Polish
1. Add image caching
2. Implement offline support
3. Add error handling and loading states

