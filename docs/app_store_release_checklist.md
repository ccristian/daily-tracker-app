# App Store Release Checklist

## Before App Store Connect
- Apple Developer Program account approved and active
- Bundle identifier confirmed as `com.ccristian.bonora`
- Version set in `pubspec.yaml` to `0.0.1+1`
- App tested on a real iPhone
- App icon and launch assets verified
- Support URL prepared
- Privacy Policy URL prepared
- Screenshots prepared

## App Store Connect Setup
- Create app in App Store Connect
- App name: `Bonora`
- Bundle ID: `com.ccristian.bonora`
- SKU created, for example `bonora001`
- Primary language selected

## Xcode Signing
- Open `ios/Runner.xcworkspace`
- Select `Runner` target
- Enable `Automatically manage signing`
- Select your Apple Developer team
- Confirm bundle identifier is `com.ccristian.bonora`

## Build
- Run `flutter pub get`
- Run `flutter build ipa --release --build-name 0.0.1 --build-number 1`
- Confirm `.ipa` exists in `build/ios/ipa/`

## Upload
- Upload the `.ipa` with Transporter or Xcode Organizer
- Wait for App Store Connect processing to finish

## Store Listing
- Description entered
- Keywords entered
- Support URL entered
- Privacy Policy URL entered
- Category selected
- Age rating completed
- Screenshots uploaded
- App Privacy answers completed
- Price set to `Free`

## Review
- Build attached to version `0.0.1`
- Review contact details completed
- Review notes completed
- Submit for review

## After Submission
- Watch App Store Connect for review status
- If rejected, fix issue, increment build number, rebuild, and upload again
