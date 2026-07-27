
## 1.1.4

- Added `example/` to comply with pub.dev package guidelines.

## 1.1.3

- Fix Stable Version & Docs.

## 1.1.2

- Fix Stable Version & Docs.

## 1.1.1

- Fix Bug.

## 1.1.0

- Added `check` command to verify 16KB alignment status of all `.so` files.
- Run `dart run android_16kb_patcher:check` to see a detailed report grouped by architecture.
- Reports PASS/FAIL status with alignment details (4KB, 16KB, 64KB).

## 1.0.3

- Fix bug: string interpolation nhttps://x.com/xxibgfiyot rendering variable correctly in print output.

## 1.0.2

- Fix bug: default directory path displayed as literal text instead of actual value.

## 1.0.1

- Fix bug: homepage and repository URL correction.

## 1.0.0

- Initial release.
- Automatically scan and patch 4KB ELF alignments to 16KB in Android native libraries (.so).
- Out-of-the-box support for `android/app/src/main/jniLibs` default path.
