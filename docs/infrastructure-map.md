# Infrastructure & Deployment Map

**Cloud Provider**: Google Cloud Platform (GCP) via Firebase
**Region**: `us-central1` (Default) or `southamerica-east1` (Likely for BR latency)

## 1. Firebase Services Configuration

### 1.1 Authentication (`firebase_auth`)
*   **Methods**:
    *   **Email/Password**: Primary provider.
    *   **Social**: Google/Apple (configured in console).
*   **Security**: Use of `firebase_app_check` (App Check) to prevent abuse.

### 1.2 Database (`cloud_firestore`)
*   **Type**: NoSQL Document Store.
*   **Collections**:
    *   `users`: Core user profiles.
    *   `matches`: MatchPoint relationships.
    *   `chats` / `messages`: Conversation data.
    *   `feedback` / `tickets`: Support system.
*   **Rules**: `firestore.rules` file governs read/write access.

### 1.3 Storage (`firebase_storage`)
*   **Buckets**: Default Google Cloud Storage bucket.
*   **Folder Structure**:
    *   `users/{uid}/profile/`: Avatars.
    *   `users/{uid}/gallery/`: Portfolio media (Images/Videos).
    *   `chat/{conversationId}/`: Shared media.

### 1.4 DevOps & Monitoring
*   **Analytics**: `firebase_analytics` tracking user events (Screen views, conversions).
*   **Crashlytics**: (Implied standard) Crash reporting.
*   **Remote Config**: (Potential) Feature flags.

## 2. Native Capabilities & Permissions

### 2.1 Android (`AndroidManifest.xml`)
*   `ACCESS_FINE_LOCATION`: For MatchPoint radar.
*   `CAMERA` / `READ_EXTERNAL_STORAGE`: For Media Upload.
*   `RECORD_AUDIO`: For Guitar Tuner (Microphone access).
*   `INTERNET`: Basic connectivity.

### 2.2 iOS (`Info.plist`)
*   `NSLocationWhenInUseUsageDescription`
*   `NSCameraUsageDescription`
*   `NSPhotoLibraryUsageDescription`
*   `NSMicrophoneUsageDescription`

## 3. CI/CD Pipeline (Recommended)

### 3.1 Environments
*   **Dev**: Local emulator or Dev Firebase Project.
*   **Prod**: Production Firebase Project.

### 3.2 Build Commands
*   `flutter build appbundle`: For Play Store.
*   `flutter build ipa`: For App Store.
*   `flutter pub run build_runner build`: To generate code (`.g.dart`, `.freezed.dart`).
