# NotingDown for iOS

A native SwiftUI note-taking app for iPhone and iPad, with local Core Data
persistence, search, categories, favorites, speech-to-text notes, haptics and export.

[Open the Xcode project](NotingDown.xcodeproj) · [Quality and test guide](docs/QUALITY.md) · [MIT license](LICENSE)

## Run

Use Xcode 16.2 or newer on macOS. Open `NotingDown.xcodeproj`, select the shared
`NotingDown` scheme and an iPhone or iPad simulator, then press Cmd+R.
The deployment target is iOS/iPadOS 16.6. Select your own development team only
when signing for a physical device; simulator builds need no signing credentials.

## What is implemented

- Create, edit, favorite, search, categorize, delete and share notes stored on-device.
- Core Data filtering and sorting, batched fetching, and debounced search.
- Voice input using Apple Speech, saving the resulting transcript as note text.
- Dynamic Type, labeled note controls, selected category traits and Reduce Motion support.
- English and Spanish localization for the main note, search, editor, settings and voice flows.
- XCTest unit, persistence, export, performance and UI test targets.
- A macOS GitHub Actions workflow scoped to this iOS project, producing test results,
  coverage, screenshots and a demo recording.

Notes work offline. Speech recognition may need the network depending on device
and language. There is **no CloudKit/iCloud synchronization**. Voice audio and image
attachments are not persisted; formatting currently saves as plain text.
Some analytics and template prose still uses English.

## Test and demo

On a Mac, run these from the repository root:

```sh
python3 NotingDownIOS/scripts/validate.py
python3 NotingDownIOS/scripts/ci.py test
python3 NotingDownIOS/scripts/ci.py demo
```

The UI walkthrough creates a note, searches its body, opens details and edits it.
It produces real simulator screenshot attachments and a short `demo.mp4` under
`NotingDownIOS/artifacts/`. The [iOS workflow](../.github/workflows/ios.yml) uploads
these as `ios-evidence` after a successful run. UI tests use a separate SQLite
store through Debug-only launch arguments, leaving normal app data separate.

The updated app has not yet been built or run on a simulator in this Windows
workspace. Fresh screenshots, a video, coverage numbers and benchmark timings
must come from the first successful macOS run; none are claimed here.

## Historical screenshots

These checked-in captures are from February 2025 and show the earlier released
interface, not the updated UI. Use the CI captures when preparing current
portfolio material.

<img src="NotingDown/ReleseImages/iphone/Simulator Screenshot - iPhone 16 Pro Max - 2025-02-22 at 22.30.06.png" alt="Historical iPhone notes screen, February 2025" width="260">
<img src="NotingDown/ReleseImages/iphone/Simulator Screenshot - iPhone 16 Pro Max - 2025-02-22 at 22.30.12.png" alt="Historical iPhone note detail, February 2025" width="260">

## Performance evidence

The 2,000-note SQLite benchmark records query wall-clock time and memory while
checking result correctness. UI tests also measure launch time. See
[the measurement protocol](docs/QUALITY.md#performance-work-and-measurement)
for collecting a baseline and reporting results without inventing speedup claims.

## Portfolio wording

> Built a native SwiftUI iOS note-taking app with local Core Data persistence,
> search, speech-to-text notes, haptics and export; added XCTest coverage,
> simulator CI, accessibility improvements and English/Spanish localization.

Only add test-pass, coverage or performance numbers after obtaining the corresponding
CI results. The [license](LICENSE) applies to the iOS directory only.
