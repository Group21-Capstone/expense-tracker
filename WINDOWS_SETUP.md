# Expense Analyzer — Windows 11 Setup & Run Guide (Android Studio)

A complete, **zero-assumptions** guide to build and run this Flutter app on a **fresh Windows 11 machine** with nothing installed. Follow the steps in order. Every command and click is spelled out.

> **What this app is:** a Flutter mobile app (an expense / budget tracker) that uses
> **Supabase** for login + database and **Groq** for an AI chat assistant. You will install
> the toolchain, configure two API keys, set up the database, then run the app on an
> Android emulator or a physical phone.

---

## Table of contents

1. [What you are about to install](#1-what-you-are-about-to-install)
2. [System requirements](#2-system-requirements)
3. [Install Git for Windows](#3-install-git-for-windows)
4. [Install the Flutter SDK](#4-install-the-flutter-sdk)
5. [Install Android Studio](#5-install-android-studio)
6. [Install the Android SDK components (inside Android Studio)](#6-install-the-android-sdk-components-inside-android-studio)
7. [Accept Android licenses & run `flutter doctor`](#7-accept-android-licenses--run-flutter-doctor)
8. [Get the project onto your machine](#8-get-the-project-onto-your-machine)
9. [Open the project in Android Studio](#9-open-the-project-in-android-studio)
10. [Configure secrets — create the `.env` file](#10-configure-secrets--create-the-env-file)
11. [Set up the Supabase backend](#11-set-up-the-supabase-backend)
12. [Install project dependencies](#12-install-project-dependencies)
13. [Create a device to run on (emulator or phone)](#13-create-a-device-to-run-on-emulator-or-phone)
14. [Run the app](#14-run-the-app)
15. [Build a release APK (optional)](#15-build-a-release-apk-optional)
16. [Troubleshooting](#16-troubleshooting)

---

## 1. What you are about to install

| Tool | Why | Approx. size |
|------|-----|--------------|
| Git for Windows | Download the project + version control | ~60 MB |
| Flutter SDK (stable) | The framework this app is built with | ~1 GB unzipped |
| Android Studio | IDE + Android SDK + emulator | ~1 GB installer, ~8–10 GB after SDKs |
| Android SDK Platform 36, Build-Tools 36.1.0, NDK 28.2.13676358, Platform-Tools, Emulator | Required to compile and run the app on Android | several GB |
| Java (JDK 17) | Bundled inside Android Studio — **do not install separately** | included |

Budget **15–25 GB of free disk space** and a stable internet connection. The first build downloads a lot.

---

## 2. System requirements

- **Windows 11** 64-bit (x64). (Windows 10 64-bit also works.)
- **8 GB RAM minimum**, 16 GB strongly recommended (the Android emulator is heavy).
- **20+ GB free disk space.**
- Administrator rights on the machine.
- **Hardware virtualization enabled in BIOS/UEFI** (needed for a fast emulator). It is on by default on most modern PCs. If the emulator later refuses to start, see [Troubleshooting](#16-troubleshooting).

> **Tip on paths:** Install everything to short, space-free paths (e.g. `C:\src\flutter`, not `C:\Users\My Name\Flutter`). Spaces and very long paths break Android/Gradle builds on Windows.

---

## 3. Install Git for Windows

1. Open Microsoft Edge and go to **https://git-scm.com/download/win**.
2. The 64-bit installer downloads automatically. Run it (double-click the file in your Downloads folder).
3. Click **Next** through every screen accepting the defaults. The defaults are fine for this project.
4. Click **Install**, then **Finish**.
5. Verify: press **Start**, type `cmd`, press **Enter** to open Command Prompt, then run:
   ```bat
   git --version
   ```
   You should see something like `git version 2.x.x.windows.1`.

---

## 4. Install the Flutter SDK

This project targets the **stable** channel with Dart SDK `^3.6.2` (i.e. Dart 3.6.2 or newer). The latest stable Flutter satisfies this.

1. Go to **https://docs.flutter.dev/get-started/install/windows/mobile**.
2. Download the latest **stable Flutter SDK zip** (a file named like `flutter_windows_3.x.x-stable.zip`).
3. Create the folder `C:\src` (open File Explorer, go to `C:\`, right-click → **New → Folder**, name it `src`).
4. Extract the zip **into `C:\src`** so you end up with `C:\src\flutter` (inside it you should see `bin`, `packages`, etc.).
   - Right-click the zip → **Extract All…** → set the destination to `C:\src` → **Extract**.
   - ⚠️ Do **not** extract to `C:\Program Files` (it needs admin write access and breaks updates).
5. **Add Flutter to your PATH:**
   1. Press **Start**, type `environment variables`, click **Edit the system environment variables**.
   2. Click **Environment Variables…**.
   3. Under **User variables**, select **Path** → **Edit…** → **New** → paste:
      ```
      C:\src\flutter\bin
      ```
   4. Click **OK** on all three dialogs.
6. **Close and reopen** Command Prompt (PATH changes only apply to new windows). Then verify:
   ```bat
   flutter --version
   ```
   You should see the Flutter and Dart versions. The first run may take a moment as it bootstraps.

---

## 5. Install Android Studio

Android Studio gives you the Android SDK, the emulator, and a bundled JDK — all required.

1. Go to **https://developer.android.com/studio**.
2. Click **Download Android Studio**, accept the terms, and run the downloaded `.exe`.
3. In the setup wizard:
   - **Welcome → Next.**
   - **Choose Components:** keep **Android Studio** and **Android Virtual Device** checked → **Next**.
   - Accept the install location default → **Next** → **Install** → **Finish** (leave "Start Android Studio" checked).
4. On first launch, the **Setup Wizard** appears:
   - **Do not import settings** → OK.
   - Choose **Standard** install type → **Next**.
   - Pick a UI theme → **Next**.
   - **Verify Settings:** it lists the Android SDK, an SDK Platform, and the emulator to download → **Next** → **Accept** all licenses → **Finish**.
   - It downloads the base SDK. Wait for it to finish, then click **Finish**.

You should now see the Android Studio **Welcome** window.

---

## 6. Install the Android SDK components (inside Android Studio)

This project needs specific SDK pieces: **Platform 36**, **Build-Tools 36.1.0**, **NDK 28.2.13676358**, plus Platform-Tools and the Emulator.

1. In the Android Studio Welcome window, click the **⋮ (More Actions)** menu → **SDK Manager**.
   (If a project is open instead: **File → Settings → Languages & Frameworks → Android SDK**.)
2. Go to the **SDK Platforms** tab:
   - Check the box for **Android API 36** (Android 16 / "Baklava"). If you only see lower APIs, check the highest available — but 36 is what this project compiles against.
   - In the bottom-right, tick **Show Package Details** to confirm "Android SDK Platform 36" is selected.
3. Go to the **SDK Tools** tab and tick **Show Package Details** (bottom-right). Then check:
   - **Android SDK Build-Tools** → expand and tick **36.1.0**.
   - **NDK (Side by side)** → expand and tick **28.2.13676358**.
   - **Android SDK Platform-Tools** (for `adb`).
   - **Android SDK Command-line Tools (latest)** (needed for `flutter doctor --android-licenses`).
   - **Android Emulator**.
   - **Android Emulator hypervisor driver** (only appears on Intel CPUs — tick it if present).
4. Click **Apply** → **OK** → accept licenses → wait for all downloads to complete → **Finish**.

> **Note the SDK location** shown at the top of the SDK Manager — typically
> `C:\Users\<YourName>\AppData\Local\Android\Sdk`. You may need it later. Flutter usually
> finds it automatically.

---

## 7. Accept Android licenses & run `flutter doctor`

1. Open a **new** Command Prompt.
2. Tell Flutter where Android Studio is (usually auto-detected; this is just to be safe):
   ```bat
   flutter doctor
   ```
3. Accept all Android SDK licenses (type `y` and Enter at each prompt):
   ```bat
   flutter doctor --android-licenses
   ```
4. Run the doctor again and read the output:
   ```bat
   flutter doctor
   ```
   You want green check marks (✓) for:
   - **Flutter**
   - **Android toolchain — develop for Android devices**
   - **Android Studio**

   You can **ignore** warnings about Chrome, Visual Studio (that's for Windows desktop apps, not needed here), and any connected-device line for now. If "Android toolchain" has a ✗ or ⚠, follow its exact instruction (usually a missing license or component) and re-run.

---

## 8. Get the project onto your machine

If you already have the project folder (this guide lives inside it), **skip to step 9**.

Otherwise, clone or copy it. To clone from a Git remote:

1. Open Command Prompt and choose a working folder, e.g.:
   ```bat
   mkdir C:\projects
   cd C:\projects
   ```
2. Clone (replace the URL with your repository's URL):
   ```bat
   git clone <YOUR-REPOSITORY-URL> expense-tracker
   cd expense-tracker
   ```

If you received the project as a **zip**, extract it into `C:\projects\expense-tracker` (avoid spaces in the path).

---

## 9. Open the project in Android Studio

1. Launch Android Studio.
2. On the Welcome screen click **Open** (not "New Project").
3. Navigate to the project folder (e.g. `C:\projects\expense-tracker`) and select the **root folder** (the one that contains `pubspec.yaml`). Click **OK**.
4. If prompted **"Trust project?"** → click **Trust Project**.
5. Android Studio may suggest installing the **Flutter** and **Dart** plugins. Install them:
   - **File → Settings → Plugins → Marketplace**, search **Flutter**, click **Install** (it installs Dart automatically), then **Restart IDE** when prompted.
6. After restart, reopen the project. Android Studio will index the files and may start downloading Gradle. Let it finish (watch the status bar at the bottom).

> The Android build uses **Gradle 8.13**, **Android Gradle Plugin 8.11.1**, and **Kotlin 2.2.20**.
> These are pinned by the project and downloaded automatically on first build — you do not install them by hand.

---

## 10. Configure secrets — create the `.env` file

The app reads three values at **build time** (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GROQ_API_KEY`). They are **not** committed to git (`.env` is git-ignored), so you must create the file yourself.

1. In the project **root folder** (same folder as `pubspec.yaml`), create a new file named exactly:
   ```
   .env
   ```
   In Android Studio: right-click the project root in the Project pane → **New → File** → type `.env` → Enter.

2. Paste the following and fill in your own values:
   ```env
   SUPABASE_URL=https://YOUR-PROJECT-ref.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   GROQ_API_KEY=your-groq-api-key
   ```
   - Get `SUPABASE_URL` and `SUPABASE_ANON_KEY` after [step 11](#11-set-up-the-supabase-backend).
   - Get `GROQ_API_KEY` from **https://console.groq.com** → sign up (free) → **API Keys → Create API Key**. (The AI chat assistant won't work without it, but the rest of the app will.)

3. Save the file.

> **How the keys reach the app:** at run time you pass `--dart-define-from-file=.env` (the
> run command in [step 14](#14-run-the-app) does this for you). Flutter reads each `KEY=VALUE`
> line and injects it via `String.fromEnvironment` in `lib/core/app_config.dart`. There is **no**
> runtime dotenv loader — the values are baked into the build, so **you must re-run the app
> after changing `.env`.**

---

## 11. Set up the Supabase backend

The app needs a Supabase project with two tables and security rules. A SQL script (`supabase_setup.sql`) is included.

1. Go to **https://supabase.com** and sign up (free tier is fine).
2. Click **New project**. Pick an organization, give it a name, set a database password (save it somewhere), choose a region close to you, and click **Create new project**. Wait ~2 minutes for it to provision.
3. **Get your keys:** in the project, go to **Project Settings (gear icon) → API**. Copy:
   - **Project URL** → this is `SUPABASE_URL`.
   - **anon / public** key (under "Project API keys") → this is `SUPABASE_ANON_KEY`.

   Put both into your `.env` file from [step 10](#10-configure-secrets--create-the-env-file).
4. **Create the tables and security policies:**
   - In the Supabase dashboard, open **SQL Editor → New query**.
   - Open `supabase_setup.sql` from this project, copy its **entire** contents, paste into the editor, and click **Run**. It creates the `transactions` and `budgets` tables, indexes, and Row-Level-Security policies.
5. **Make sign-up log in immediately (recommended for testing):**
   - Go to **Authentication → Providers → Email** (or **Authentication → Sign In / Providers**).
   - **Turn OFF "Confirm email."** This lets a new account log in right after sign-up without checking an inbox. Save.

> The anon key is safe to ship in a client because every table is protected by Row-Level
> Security (each user only sees their own rows). The Groq key is **not** safe to ship in a
> production release — it's fine for this demo/prototype.

---

## 12. Install project dependencies

1. Open the **Terminal** inside Android Studio (**View → Tool Windows → Terminal**), or a Command Prompt `cd`'d into the project root.
2. Fetch the Dart/Flutter packages listed in `pubspec.yaml`:
   ```bat
   flutter pub get
   ```
   This downloads `supabase_flutter`, `provider`, `fl_chart`, `http`, `shared_preferences`, `intl`, `uuid`, etc. Wait for **"Got dependencies!"**.

---

## 13. Create a device to run on (emulator or phone)

Pick **one** of the two options.

### Option A — Android Emulator (no physical phone needed)

1. In Android Studio open the **Device Manager** (phone icon on the right toolbar, or **Tools → Device Manager**).
2. Click **+ → Create Virtual Device** (or **Add a new device → Create Virtual Device**).
3. Pick a phone, e.g. **Pixel 7** → **Next**.
4. Choose a **system image**. Pick a recent one (e.g. API 34 or 35) with the **download** icon → click the download icon → accept license → **Finish** → **Next**.
   - You do **not** need API 36 for the *emulator image*; the app's `minSdk`/`targetSdk` come from Flutter and run fine on recent images.
5. Name it → **Finish**.
6. In Device Manager, click the **▶ (Play)** button next to your new emulator to boot it. Wait until you see the Android home screen.

### Option B — Physical Android phone

1. On the phone: **Settings → About phone → tap "Build number" 7 times** to unlock Developer options.
2. **Settings → System → Developer options → enable "USB debugging."**
3. Connect the phone to the PC with a USB cable. On the phone, tap **Allow** on the "Allow USB debugging?" prompt.
4. Verify the PC sees it:
   ```bat
   flutter devices
   ```
   Your phone should be listed. (If not, you may need your phone maker's USB driver; see Troubleshooting.)

---

## 14. Run the app

With an emulator booted **or** a phone connected:

1. Confirm a device is available:
   ```bat
   flutter devices
   ```
2. Run the app, passing your secrets file:
   ```bat
   flutter run --dart-define-from-file=.env
   ```
   - The **first** build is slow (Gradle downloads dependencies — several minutes). Subsequent runs are much faster.
   - When it finishes, the app launches on your device/emulator.

3. **Hot reload while developing:** with `flutter run` active in the terminal, press **`r`** to hot-reload, **`R`** to hot-restart, **`q`** to quit.

### Running from the Android Studio UI instead of the terminal

The green **Run ▶** button does **not** pass `--dart-define-from-file` by default, so the app would launch without keys. Configure it once:

1. Top toolbar → click the run-configuration dropdown (says **main.dart**) → **Edit Configurations…**.
2. Select your Flutter configuration.
3. In **Additional run args** (or "Additional arguments"), enter:
   ```
   --dart-define-from-file=.env
   ```
4. Make sure your emulator/phone is selected in the device dropdown, then click **Run ▶**.

### First-run sanity check

- The landing page appears → tap **Sign up**, create an account (email + password).
- If "Confirm email" is off (step 11.5), you're logged straight in.
- Add a transaction, set a budget, view reports. Open the chat assistant ("Fin") — it works only if `GROQ_API_KEY` is set.

---

## 15. Build a release APK (optional)

To produce an installable APK:

```bat
flutter build apk --release --dart-define-from-file=.env
```

The APK is written to:
```
build\app\outputs\flutter-apk\app-release.apk
```
Copy it to a phone and install (you'll need to allow "install from unknown sources"). This build is signed with debug keys (fine for testing, **not** for the Play Store).

For a smaller, per-architecture set of APKs:
```bat
flutter build apk --release --split-per-abi --dart-define-from-file=.env
```

---

## 16. Troubleshooting

**`flutter` or `git` is not recognized**
The PATH entry didn't take. Reopen the terminal (PATH only applies to new windows). Recheck step 4.5 — the entry must be `C:\src\flutter\bin`.

**`flutter doctor` shows ✗ Android toolchain / "cmdline-tools component is missing"**
Open Android Studio → SDK Manager → **SDK Tools** tab → check **Android SDK Command-line Tools (latest)** → Apply. Then run `flutter doctor --android-licenses` again.

**`flutter doctor` shows "Unable to locate Android SDK"**
Point Flutter at it explicitly (use your actual SDK path from step 6):
```bat
flutter config --android-sdk "C:\Users\<YourName>\AppData\Local\Android\Sdk"
```

**Gradle build fails / NDK or Build-Tools "not found"**
You're missing a pinned component. In SDK Manager → SDK Tools → **Show Package Details**, ensure **Build-Tools 36.1.0** and **NDK 28.2.13676358** are installed (step 6). Then `flutter clean` and run again.

**Build fails after editing `.env`, or keys "not configured" in-app**
Secrets are baked in at build time. Stop the app and re-run with `--dart-define-from-file=.env`. Confirm `.env` is in the project **root** (next to `pubspec.yaml`) and each line is `KEY=VALUE` with no quotes or spaces around `=`.

**Login/sign-up fails or hangs**
Check `SUPABASE_URL` / `SUPABASE_ANON_KEY` in `.env` match the **Project Settings → API** values. Make sure you ran `supabase_setup.sql`. If sign-up succeeds but you're not logged in, turn **off** "Confirm email" (step 11.5).

**AI chat ("Fin") says the key isn't configured**
`GROQ_API_KEY` is empty or invalid. Get a key from https://console.groq.com and re-run with `--dart-define-from-file=.env`.

**Emulator won't start / is extremely slow**
Hardware virtualization is likely disabled. Reboot into BIOS/UEFI and enable **Intel VT-x** (Intel) or **SVM / AMD-V** (AMD). On Windows also ensure the **Windows Hypervisor Platform** feature is on (Start → "Turn Windows features on or off"). Alternatively, use a physical phone (step 13, Option B).

**Phone not detected by `flutter devices`**
Re-check USB debugging is on and you tapped **Allow** on the phone. Try a different USB cable/port. For some brands install the OEM USB driver. Run `adb devices` (from `...\Android\Sdk\platform-tools`) to confirm `adb` sees it.

**`flutter clean` to recover from a broken build**
```bat
flutter clean
flutter pub get
flutter run --dart-define-from-file=.env
```

**Gradle / build is mysteriously failing on a long or spaced path**
Move the project to a short path like `C:\projects\expense-tracker` and rebuild.

---

### Quick command reference

```bat
flutter --version                                   :: check Flutter install
flutter doctor                                      :: diagnose toolchain
flutter doctor --android-licenses                   :: accept Android licenses
flutter pub get                                     :: install dependencies
flutter devices                                     :: list emulators/phones
flutter run --dart-define-from-file=.env            :: run the app (debug)
flutter build apk --release --dart-define-from-file=.env   :: build release APK
flutter clean                                       :: clear build artifacts
```
