# SimpleNoise-PlainPlane

Ambient noise generator Android app with white, pink, brown, grey, and black noise.

## Features

- 2D noise pad: X-axis controls noise color, Y-axis controls stereo spread and texture
- Brownian noise-driven grain modulation for organic, non-repeating texture
- Color wandering between adjacent noise types (L wanders left, R wanders right)
- A-weighted loudness equalization across all noise types
- Static visual grain overlay on the pad
- PWA support with service worker and manifest

## Build

1. Install Node.js, Java JDK 11+, and Android Studio
2. Run `build-apk.bat` to build debug APK and signed AAB
3. APK output: `noise-android\platforms\android\app\build\outputs\apk\debug\`
4. AAB output: `noise-android\platforms\android\app\build\outputs\bundle\release\`

## Screenshots

Run `node screenshots.js` to generate Play Store screenshots (requires Puppeteer).
