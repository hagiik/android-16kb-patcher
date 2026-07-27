# Android 16KB Patcher

A simple, fast, and automated Dart CLI tool to permanently patch Android native libraries (`.so` files) from 4KB to 16KB memory page alignment. 

This tool acts as a lifesaver for developers encountering Google Play's strict **16 KB memory page sizes** requirement (enforced for Android 15+) who rely on legacy third-party vendor SDKs or precompiled `.so` files that cannot be easily updated.

## The Problem
Google Play now mandates that all native libraries must be aligned to 16KB. If your app includes old hardware SDKs (like RFID scanners, thermal printers, etc.) that were compiled with 4KB alignment (`align 2**12`), the Play Store will reject your APK/AAB, and it will crash on real Android 15 devices.

## The Solution
This tool physically patches the ELF headers (`PT_LOAD` segments) of your `.so` files in place, forcing them into a 16KB alignment (`align 2**14`) without breaking the internal C++ logic. 

## Installation

Add it as a dev dependency in your `pubspec.yaml`:

```yaml
dev_dependencies:
  android_16kb_patcher: ^1.1.0
```

## Usage

Simply run the tool from your Flutter project root:

```bash
dart run android_16kb_patcher
```

By default, the script will automatically scan and patch all `.so` files located inside `android/app/src/main/jniLibs`. 

If your `.so` files are in a different directory, you can specify the path:

```bash
dart run android_16kb_patcher path/to/your/custom_folder
```

## Verify Alignment

After patching (or anytime), you can verify the alignment status of all your `.so` files:

```bash
dart run android_16kb_patcher:check
```

This will output a detailed report grouped by architecture:

```
==========================================
  16KB PAGE SIZE ALIGNMENT CHECKER
==========================================

  [arm64-v8a]
    [+] PASS  ExampleLib.so  (align 2**14 = 16KB)
    [+] PASS  libflutter.so  (align 2**16 = 64KB)

  [armeabi-v7a]
    [+] PASS  ExampleLib.so  (align 2**14 = 16KB)

==========================================
  RESULT: 3 passed, 0 failed
==========================================

  All libraries are 16KB aligned!
  Your app is ready for Android 15+.
```

You can also specify a custom directory:

```bash
dart run android_16kb_patcher:check path/to/your/custom_folder
```

### Important Follow-up Step
To ensure the Android OS does not try to extract and compress the libraries incorrectly, ensure your `AndroidManifest.xml` includes `android:extractNativeLibs="true"` inside the `<application>` tag.

## Acknowledgements
Based on the original Python implementation by [syafiyft/android-16kb-fix](https://github.com/syafiyft/android-16kb-fix). Rewritten in Dart so Flutter developers can use it without installing Python.
