# Lazim (لازم)

A shared family needs list. One portal for everything the home needs, so it stops
living in scattered WhatsApp threads.

Arabic-first, English second, RTL throughout. Built to be stupid easy: one tap to
add, one tap to complete.

---

## Run it right now

No Firebase project, no API keys, no config. The app ships with a local backend
that seeds a demo family so you can see the whole thing working.

```powershell
cd lazim
flutter pub get
flutter run
```

That is it. Data lives in memory for the session; the demo family "Home" comes
pre-seeded with six items so the list screen is not empty.

---

## What is built

**Core loop**
- Add a need: title, note, quantity, unit, priority (low/normal/urgent), category.
- One-tap complete from the list, or from the detail screen.
- Claim an item ("I'll get it") so two people do not buy the same milk.
- Reopen a completed item.
- Assign to a family member.

**History**
- Every completed/archived item, newest first.
- Filter by status, category, priority, assignee, date range, plus free-text search.
- Filters combine, and the active count shows on the filter button.

**Attachments**
- Links, images, PDFs, Word docs, anything else.
- Images preview inline; everything else opens in the system viewer.
- Stored per item, deletable.

**Activity trail**
- Every status change, assignment, edit and attachment is recorded with who and when.
- Shown as a timeline on the item detail screen.

**Family group**
- Create a family, or join one with an invite code.
- Invite by **code** (`LAZIM-XXXXXX`), which the other person types into "Join a family".
- Owner can remove members; members can leave.
- Multiple families per user, switchable from the header.

**Language and theme**
- Arabic (default) and English, switchable in Settings, persisted.
- Full RTL layout in Arabic.
- Light and dark themes.
- Cairo typeface for both scripts so the two languages sit at the same weight.

**Notifications** (Firebase mode, no billing account needed)
- New item added → everyone else in the family is notified.
- Status changed → everyone else is notified.
- Localised per recipient (Arabic default), actor excluded, no repeats.
- Implemented as **local notifications driven by the live Firestore listener**
  (`lib/core/local_notifier.dart`). Firebase Cloud Messaging delivery is free on
  the Spark plan, but the Firestore→send trigger (Cloud Functions) is Blaze-only,
  so this approach avoids a billing account entirely. Tradeoff: notifications
  fire while the app process is alive, not after a force-kill. FCM token
  registration (`lib/core/push_registration.dart`) remains wired for a future
  true-push upgrade.

---

## Architecture

Layered, with the backend behind interfaces so it can be swapped or extended
without touching the UI.

```
lib/
  core/
    config.dart        build-time flags (backend, invite base URL)
    theme.dart         design system: colours, typography, component themes
    providers.dart     Riverpod graph — the one place that picks local vs Firebase
    router.dart        go_router with auth gate + invite link capture
    formatting.dart    localised labels, relative dates, byte sizes
  domain/
    enums.dart         status/priority/category/role/attachment/activity
    models.dart        AppUser, Family, FamilyMember, NeedItem, Attachment,
                       ActivityEntry, NeedFilter
  data/
    repositories.dart  the contracts (Auth, Family, Need, Preferences, Push)
    local_repository.dart    in-memory + SharedPreferences implementation
    firebase_repository.dart Firestore + Auth + Storage + FCM implementation
  ui/
    shell.dart         bottom navigation
    widgets/           NeedCard, common primitives
    screens/           sign_in, family_setup, needs_list, need_detail,
                       need_editor, history, settings
  l10n/                app_en.arb, app_ar.arb
```

**The seam that matters:** `data/repositories.dart` defines five interfaces.
Everything above them is backend-agnostic. To add a new backend (Supabase,
your own API), implement those five and change one provider. To add a feature,
add a method to the interface and implement it twice.

**Adding a feature, concretely:**
1. Add the field to the model in `domain/models.dart` (with `toMap`/`fromMap`).
2. Add the method to the relevant interface in `data/repositories.dart`.
3. Implement it in both `local_repository.dart` and `firebase_repository.dart`.
4. Add strings to both ARB files.
5. Build the UI against the provider.

No step touches unrelated code.

---

## Going live with Firebase

**This is already done.** The app is wired to the live Firebase project
`lazim-51935` and defaults to the Firebase backend. Google sign-in, shared
Firestore sync and the deployed security rules all work. This section documents
how it is set up, for reference or if you ever rebuild it.

### Current setup (working)

| Piece | Value |
|---|---|
| Firebase project | `lazim-51935` |
| Android package | `com.amworx.lazim` |
| Config | `lib/core/firebase_config.dart` (from `google-services.json`) |
| `google-services.json` | `android/app/google-services.json` |
| Signing key | local only: `android/app/lazim.keystore` + `android/key.properties` (gitignored; SHA-1 `06:EA:25:AD:...`) |
| Rules | `firebase/firestore.rules`, deployed to `lazim-51935` |

Two things make Google sign-in work and are easy to break:

1. **`Firebase.initializeApp()` is called with explicit `FirebaseOptions`**
   (`lib/main.dart`). The `google-services` Gradle plugin is not applied, so
   without options Firebase fails to initialise and the app silently falls back
   to the local backend — which looks exactly like "sign-in is broken".
2. **`GoogleSignIn.instance.initialize(serverClientId: ...)`** passes the web
   OAuth client explicitly (`lib/data/firebase_repository.dart`). Without it,
   google_sign_in v7 cannot find a client and throws.

**Signing matters.** Firebase only has the *release* keystore's SHA-1
registered. A build signed with the debug keystore fails sign-in with
`ApiException: 10`. `android/app/build.gradle.kts` therefore signs *debug*
builds with the release key too, so `flutter run` works. The keystore and its
passwords are private and are **not in this repo**: copy
`android/key.properties.example` to `android/key.properties`, put your keystore
in `android/app/`, and fill in the values. Without `key.properties` the app still
builds (with the default debug key), but Google sign-in needs that key's SHA-1
registered in Firebase. If you ever use a different key, register its SHA-1:

> Project settings → Your apps → `com.amworx.lazim` → Add fingerprint

### Rebuilding from scratch

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add an **Android** app with package name `com.amworx.lazim`.
3. Enable **Authentication → Google** and **Email/Password**.
4. Enable **Firestore Database** (production mode) and **Storage**.
5. Download `google-services.json` into `android/app/`.
6. Copy the values into `lib/core/firebase_config.dart`.
7. Deploy the rules:

```powershell
npx firebase-tools deploy --only firestore:rules --project lazim-51935
```

The rules in `firebase/firestore.rules` enforce that only family members can read
or write that family's data. Nothing is world-readable.

### Switching back to the offline demo

```powershell
flutter run --dart-define=LAZIM_BACKEND=local
```

The local backend needs no Firebase config at all.


### 5. Google sign-in SHA fingerprints

Google sign-in on Android needs your signing certificate registered:

```powershell
cd android
./gradlew signingReport
```

Copy the SHA-1 and SHA-256 into Firebase console → Project settings → Your apps →
Android app → Add fingerprint. Download the refreshed `google-services.json` if
prompted.

For release builds, add the release keystore's fingerprints too, or sign-in will
work in debug and silently fail in production.

### 6. Invite links

Invitations are shared as a **code** (`LAZIM-XXXXXX`). That is the whole
mechanism, and it needs no domain: the other person opens the app, chooses
"Join a family", and types the code.

The manifest declares only the `lazim://join/*` custom scheme. There is
deliberately no `https` intent-filter, because Lazim has no hosted domain. An
earlier placeholder, `lazim.app`, turned out to belong to an unrelated owner, so
links built from it reached nobody and `autoVerify` could never succeed. That
placeholder has been removed from the config, the manifest and the share text.

If you later own a domain and want tappable links:

1. Host `https://yourdomain/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.amworx.lazim",
    "sha256_cert_fingerprints": ["YOUR:SHA256:HERE"]
  }
}]
```

2. Add an `https` intent-filter for that host in `AndroidManifest.xml`.
3. Build with `--dart-define=LAZIM_INVITE_BASE=https://yourdomain/join`.

Until then the code path is fully functional and is what the share sheet sends.

---

## Firestore data model

```
users/{uid}
  id, displayName, email, photoUrl, locale, familyIds[]

families/{familyId}
  id, name, ownerId, inviteCode, createdAt, memberCount

families/{familyId}/members/{uid}
  userId, displayName, role, joinedAt, photoUrl, fcmTokens[]

families/{familyId}/needs/{needId}
  id, familyId, title, note, quantity, unit, status, priority, category,
  createdBy, createdByName, assignedTo, assignedToName,
  createdAt, updatedAt, purchasedAt,
  attachments[], activity[]

invites/{inviteCode}
  familyId
```

`activity` and `attachments` are inline arrays rather than subcollections. That
keeps the detail screen to one document read instead of N+1 queries. If an item
ever accumulates hundreds of activity entries, split `activity` into a
subcollection — the model already has the shape for it.

---

## Tests

```powershell
flutter test
```

23 tests across three files:

- `test/domain_test.dart` (14) — filter logic (each dimension plus combinations),
  enum serialisation round-trips and unknown-code fallbacks, model map
  round-trips, attachment kind detection, status terminal semantics.
- `test/routing_test.dart` (3) — the auth gate. Signed-out users land on
  sign-in, signing in moves past the gate, and the auth stream drives it in both
  directions. These exist because the gate once silently failed open.
- `test/screens_test.dart` (6) — each screen builds against the local demo
  backend with real seeded data: needs list, history, settings, item detail, and
  locale/RTL switching.

```powershell
flutter analyze
```

Clean: zero errors, zero warnings.

---

## Known gaps

Things deliberately left for the next pass, so they are not mistaken for finished:

- **Notifications are local, not true background push.** They fire from the
  live Firestore listener while the app process is alive. A force-killed app
  will not get a notification until it is opened again. True push would need a
  free Cloudflare Worker calling FCM v1, or Firebase Blaze + Cloud Functions.
- **No offline persistence.** Firestore offline caching is one flag
  (`Settings(persistenceEnabled: true)`); not enabled yet.
- **No image compression before upload.** A 12 MP photo uploads at full size.
  Add `flutter_image_compress` before shipping.
- **No pagination.** Needs are capped at 500 per family. Fine for a household,
  not for a shared building.
- **No account deletion flow.** Required by Play Store policy before release.
- **iOS is scaffolded but unconfigured.** Needs the iOS Firebase app, an APNs key,
  and `GoogleService-Info.plist`.
- **Release signing uses debug keys.** Replace before any store upload.
- **No app icon or splash.** Default Flutter assets are still in place.
- **Self-update is sideload-only.** The in-app updater installs an APK from a
  manifest URL. That is right for direct distribution, but Google Play policy
  forbids an app updating itself, so a Play build must ship with
  `AppConfig.updateManifestUrl` empty (which disables the whole feature) and use
  Play's own update flow instead. See "In-app updates" below.

---

## In-app updates

The app can check for, download, and install its own updates without a store.
It is off by default: `AppConfig.updateManifestUrl` is empty, and an empty URL
means no network call, no timer, and no UI.

**Turn it on** by passing the manifest URL at build time:

```
flutter build apk --release \
  --dart-define=LAZIM_UPDATE_MANIFEST=https://your-host.example/lazim/update.json
```

**The manifest** is a small JSON file you host anywhere over HTTPS:

```json
{
  "version": "1.2.0",
  "buildNumber": 5,
  "apkUrl": "https://your-host.example/lazim/lazim-1.2.0.apk",
  "notes": "ما الجديد في هذا الإصدار",
  "mandatory": false
}
```

`buildNumber` is what decides "newer", not the version string, so it must match
the `+N` in `pubspec.yaml`. `notes` and `mandatory` are optional. A `notes` value
is shown in the user's language as written, so put Arabic there for this
audience.

**What the user sees.** On launch the app checks quietly; if a newer build
exists it shows a dialog with the notes and a download button. The same block
lives in Settings under "تحديثات التطبيق", showing the installed version, the
available version, download progress, and any error. A failed check never
interrupts the app.

**The install needs a permission.** Android requires the user to allow
"install unknown apps" for Lazim. The app checks this before downloading and,
if it is missing, sends the user to the exact system settings screen and
re-checks when they return. It does not silently fail.

**Two things that are easy to get wrong**, both fixed here and worth keeping:

- The APK must be downloaded under `getApplicationSupportDirectory()`, not
  `getApplicationDocumentsDirectory()`. On Android the documents directory is
  `app_flutter/`, which is outside `getFilesDir()` and therefore outside the
  FileProvider's `<files-path>` root, so `getUriForFile` throws "Failed to find
  configured root" and the installer never opens.
- The launch prompt lives in `MaterialApp.builder`, which is *above* the
  Navigator, so `showDialog(context: context)` throws and the dialog silently
  never appears. It uses `rootNavigatorKey.currentContext` instead.

Downloaded APKs are deleted on the next launch, because the install intent hands
off to the system installer and the app is killed before it can clean up in the
same run. A debug APK is ~180 MB, so leaving them would quietly eat storage.

**Debug builds** allow cleartext HTTP (`android/app/src/debug/AndroidManifest.xml`)
so the updater can be tested against a local server via
`adb reverse tcp:8080 tcp:8080`. Release builds keep Android's default cleartext
block, so a shipped build only ever fetches over HTTPS.

---

## Design notes

**Why Arabic defaults even on an English phone.** The primary user writes Arabic.
`localeResolutionCallback` returns Arabic unless the device is explicitly English.
A user who wants English switches once in Settings and it persists.

**Why one-tap complete is on the list row.** The most frequent action by far is
"I bought this." Burying it behind a detail screen would be the difference between
an app that gets used and one that gets abandoned.

**Why the editor is a full page, not a sheet.** Seven fields plus a keyboard on a
5-inch screen is a fight. A page gives the form room and survives back navigation.

**Why local backend exists.** A new project should be runnable in one command
before any cloud account is created. It also makes the domain logic testable
without mocking Firestore.
