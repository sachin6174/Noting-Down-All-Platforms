# iOS verification

The implementation was edited on Windows. Swift syntax and repository checks can
run there; UIKit, Core Data and simulator tests require Xcode on macOS.
Test source files are not evidence of passing tests. Use a successful iOS workflow
run and its artifacts before quoting results on a résumé.

## Automated coverage

- SQLite create, edit, reopen and delete using the app's actual managed object model.
- Blank-title rejection without inserting or mutating a note.
- Failed-save retry without duplicate insertion or loss of unrelated pending edits.
- Case/diacritic-insensitive title and body search, combined categories/favorites,
  legacy empty categories, literal query parameters, and every sort option.
- Search debounce and JSON/CSV export with Unicode, quotes and line breaks.
- UI create, search, edit, relaunch persistence, confirmed delete, cancel and blank titles.
- Spanish core note flow at an accessibility text size.
- Launch timing and SQLite query wall-clock/memory measurements with 2,000 notes.

Run from the repository root on a Mac:

```sh
python3 NotingDownIOS/scripts/validate.py
python3 NotingDownIOS/scripts/ci.py test
python3 NotingDownIOS/scripts/ci.py demo
```

Outputs live in the ignored `NotingDownIOS/artifacts/` folder. Move a previous
run's artifacts elsewhere before repeating; result bundles are never overwritten.
CI uploads `Tests.xcresult`, `coverage.json`, environment details, screenshot
attachments, and `demo.mp4`. Download the `ios-evidence` artifact from the
successful workflow. No account credentials or signing certificates are needed.

## Performance work and measurement

The notes list previously filtered all objects and sorted them in Swift on each
render; descending descriptors were also reversed a second time. The list now
uses a Core Data predicate and sort descriptors, a fetch batch size of 40, a lazy
list and a 200 ms search debounce. Date formatting uses Foundation's cached
format styles instead of constructing a DateFormatter for each card.

`NotePerformanceTests` seeds 2,000 SQLite notes outside the measured block,
queries a combined text/category/favorite filter, checks the 200 matches and
accesses the first 40 titles. It records wall-clock and memory metrics over XCTest
iterations. UI tests separately measure application launch. These are repeatable
workloads, not measured speedup claims. No latency or improvement percentage is
claimed until run on Apple hardware.

Open `Tests.xcresult` in Xcode, record the mean and standard deviation, device,
OS, Xcode and build configuration, then set a baseline in Xcode on that same
environment. Use a Release test run for product timing claims. Compare against
the earlier revision on the same machine and dataset before reporting a speedup.
Hosted-runner timing is noisy; the workflow intentionally has no arbitrary
millisecond threshold.

## Accessibility and localization

Shared type styles scale with Dynamic Type. Main note controls have spoken names,
stable test identifiers and larger tap targets. Category selection has a selected
trait. Motion effects in the haptic style and recording indicator respect Reduce
Motion. Green text uses an adaptive darker color in light mode. English and Spanish
cover the main note, search, editor, settings and voice flows; some analytics and
template prose still falls back to English.

Before release, use VoiceOver and Accessibility Inspector on iPhone and iPad.
Check reading order, category selection, edit/save/cancel, destructive confirmation,
search, keyboard navigation, light/dark contrast and accessibility text sizes.
The UI test checks Spanish labels and a large-text editor; it is not a full
accessibility conformance audit. Verify microphone denial, speech-service failure,
pause/resume and dismissal on a physical device.

## Honest feature boundaries

Notes use local Core Data. There is no CloudKit container, iCloud entitlement or
synchronization implementation. Voice input stores the transcript, not a playable
audio attachment; Apple Speech may need a network connection depending on device
and language. Formatting is currently flattened to plain text when saved.
Image attachments and automatic saving are not offered because they were not
persisted/implemented. Category storage keys remain English to preserve old notes;
only their display labels are translated.

The license in this directory applies to the iOS project only.
