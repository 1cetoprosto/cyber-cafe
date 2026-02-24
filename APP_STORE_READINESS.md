# App Store Readiness Checklist

## Status: Ready for Submission (Code & Assets)

### 1. App Icons
- [x] AppIcon set exists in `Assets.xcassets`.
- [x] Includes 1024x1024 marketing icon.
- [x] Includes all required sizes for iPhone and iPad.

### 2. Launch Screen
- [x] `LaunchScreen.storyboard` exists.
- [x] Configured in `Info.plist` / Build Settings.

### 3. Localization
- [x] `Global.strings` exists for English (en) and Ukrainian (uk).
- [x] `InfoPlist.strings` created for English (en) and Ukrainian (uk).
- [x] App Name and Privacy Descriptions are localized.

### 4. Info.plist Configuration
- [x] `CFBundleDisplayName` set to "TrackMyCafe".
- [x] Privacy Usage Descriptions added:
    - `NSFaceIDUsageDescription`: Face ID for login.
    - [x] Removed `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` as per user request (feature disabled).
- [x] Supported Interface Orientations configured for iPhone and iPad.

### 5. Build Settings (Prod)
- [x] Version: 1.0
- [x] Build: 23
- [x] Bundle Identifier: `ICSOFT.TrackMyCafe`
- [x] Signing: Automatic (Team: Q9843C43NA)

## Required Actions before Submission
1.  **Screenshots**: Verify screenshots in App Store Connect.
2.  **Metadata**: Fill in App Name, Subtitle, Description, Keywords, Support URL, Privacy Policy in App Store Connect.
3.  **TestFlight**: Upload a build to TestFlight and test on real devices.
