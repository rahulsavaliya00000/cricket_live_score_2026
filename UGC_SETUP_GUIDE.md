# 🎯 UGC (User Generated Content) Feed Setup Guide

## Overview
A community feed where users can share content with:
- One post per page (vertical pagination)
- Newest posts first (descending by timestamp)
- Pinned admin posts always first
- Beautiful, engaging UI
- No comments, likes, or dislikes
- Optional URL hiding
- In-app URL opening

---

## 📋 Firebase Firestore Collection Schema

### Collection: `ugc_posts`

```json
{
  "id": "auto-generated (document ID)",
  "title": "string (required)",
  "content": "string (required)",
  "imageUrl": "string (optional - image URL)",
  "customTag": "string (optional - 'Featured', 'Trending', etc.)",
  "hideUrl": "boolean (default: false)",
  "externalUrl": "string (optional - link/URL)",
  "timestamp": "timestamp (server timestamp)",
  "userId": "string (required - from Firebase Auth)",
  "userName": "string (required - user's display name)",
  "userAvatar": "string (optional - user's avatar URL)",
  "views": "number (default: 0 - incremented on each view)",
  "isPinned": "boolean (default: false - admin only)",
  "createdAt": "timestamp (server timestamp)"
}
```

---

## 🔧 Setup Instructions

### 1. Create Firestore Collection
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your CricketBuzz project
3. Go to **Firestore Database**
4. Create a new collection: `ugc_posts`
5. Add a test document with the schema above

### 2. Firestore Security Rules

Add these rules to allow read access:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // UGC Feed - Read-only for all authenticated users
    match /ugc_posts/{document=**} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.userId;
    }
  }
}
```

### 3. Code Integration
✅ Already integrated:
- UGC Repository: `lib/features/ugc/data/repositories/ugc_repository.dart`
- UGC Entity: `lib/features/ugc/domain/entities/ugc_post_entity.dart`
- UGC Cubit: `lib/features/ugc/presentation/cubit/ugc_cubit.dart`
- UGC Feed Page: `lib/features/ugc/presentation/pages/ugc_feed_page.dart`
- Router: `/ugc-feed` route
- DI: Registered in injection_container.dart

### 4. Add BlocProvider to Main App

In your `AppView` class (in `main.dart`), add:

```dart
BlocProvider<UGCCubit>(
  create: (_) => sl<UGCCubit>(),
),
```

---

## 📱 Navigation

### Access UGC Feed:
```dart
context.push('/ugc-feed');
```

### From Button/Menu:
Add a button somewhere (e.g., Home page, navigation menu):

```dart
ElevatedButton(
  onPressed: () => context.push('/ugc-feed'),
  child: const Text('Community Feed'),
)
```

---

## ✨ Features

### Display Features:
- ✅ **Vertical Pagination**: Swipe up/down between posts
- ✅ **One Post Per Page**: Full-screen posts
- ✅ **Pinned First**: Admin pinned posts always show first
- ✅ **Newest First**: Descending by timestamp
- ✅ **Custom Tags**: Featured, Trending, etc.
- ✅ **View Counter**: Tracks views per post
- ✅ **User Info**: Avatar, name, timestamp
- ✅ **Image Support**: Optional post images
- ✅ **URL Display**: Shows link with "Open" button (if not hidden)

### User Actions:
- ✅ **Tap to Open URL**: Opens link in-app (currently navigates to detail page)
- ✅ **View Post**: Increments view count
- ✅ **Pull Down to Refresh**: Reloads feed
- ❌ **No Comments**: Disabled by design
- ❌ **No Likes**: Disabled by design
- ❌ **No Shares**: Not implemented

---

## 🎨 UI Layout

```
┌─────────────────────────────────────┐
│  Community Feed          [back]     │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Featured] 📌              │   │
│  │                             │   │
│  │ Post Title Here             │   │
│  │                             │   │
│  │ Long form content text goes │   │
│  │ here with multiple lines    │   │
│  │                             │   │
│  │ [Image if available]        │   │
│  │                             │   │
│  │ 🔗 https://example.com/... │   │
│  │    [Open]                   │   │
│  │                             │   │
│  ├─────────────────────────────┤   │
│  │ 👤 User Name                │   │
│  │    Jan 13, 2026      👁 234 │   │
│  └─────────────────────────────┘   │
│                                     │
│       ⬆ ⬇ Swipe to browse        │
│                                     │
└─────────────────────────────────────┘
```

---

## 📊 Data Flow

```
UGC Feed Page
    ↓
UGC Cubit (loads + manages state)
    ↓
UGC Repository (Firebase queries)
    ↓
Firestore (ugc_posts collection)
```

### State Management:
- `UGCInitial`: Initial state
- `UGCLoading`: Loading first page
- `UGCLoadingMore`: Loading next page
- `UGCLoaded`: Posts displayed
- `UGCEmpty`: No posts found
- `UGCError`: Error occurred

---

## 🚀 Creating Posts

### For Admins (Firebase Console):

1. Go to Firestore
2. Collection: `ugc_posts`
3. Add document with:

```json
{
  "title": "Welcome to CricketBuzz Community!",
  "content": "Share your cricket thoughts and updates...",
  "imageUrl": "https://...image.jpg",
  "customTag": "Featured",
  "hideUrl": false,
  "externalUrl": "https://cricketbuzz.com",
  "userId": "admin_user_id",
  "userName": "CricketBuzz",
  "userAvatar": "https://...avatar.jpg",
  "isPinned": true,
  "timestamp": "(current timestamp)",
  "views": 0
}
```

---

## 🔮 Future Enhancements

### To Add Later:
1. **WebView for URLs**: Open URLs in-app WebView instead of detail page
2. **Like/Bookmark**: Toggle to add like/bookmark features
3. **Comments**: Thread-based comments on posts
4. **Share**: Share posts to social media
5. **Create Post Screen**: User post creation UI
6. **Search/Filter**: Search and filter posts by tags
7. **Trending Algorithm**: Sort by views + engagement
8. **Admin Dashboard**: Manage posts (pin, feature, delete)
9. **Deep Linking**: Direct links to specific posts
10. **Analytics**: Track engagement metrics

---

## ⚠️ Important Notes

1. **No External Browser**: Links open in-app (via detail page for now)
2. **Privacy**: `hideUrl=true` prevents URL display
3. **View Tracking**: Views increment on page load
4. **Pagination**: Loads 1 post at a time (can change `_pageSize` in repository)
5. **Default Ordering**: Pinned posts first, then by timestamp descending
6. **User Auth**: Only authenticated users can access

---

## 🐛 Troubleshooting

### Posts not loading?
- Check Firestore collection exists: `ugc_posts`
- Verify security rules allow read access
- Check network connectivity

### URL not opening?
- Currently navigates to `/ugc-detail/{post.id}`
- Implement WebView to open URLs in-app

### View count not updating?
- Check Firestore write permissions
- Verify `views` field exists in document

---

## 📝 Sample Test Data

Use this to populate your Firestore collection:

```json
{
  "title": "IPL 2026 Predictions",
  "content": "Who do you think will win IPL 2026? Share your predictions and favorite teams!",
  "imageUrl": "https://example.com/ipl.jpg",
  "customTag": "Trending",
  "hideUrl": false,
  "externalUrl": "https://ipl.org",
  "userId": "user123",
  "userName": "Cricket Fan",
  "userAvatar": "https://example.com/avatar.jpg",
  "isPinned": false,
  "views": 0
}
```

---

Done! Your UGC feed is ready to use. 🎉

