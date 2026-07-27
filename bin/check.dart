import 'dart:io';
import 'dart:typed_data';

const int PT_LOAD = 1;

class AlignmentResult {
  final String fileName;
  final String arch;
  final int alignment;
  final bool passed;

  AlignmentResult(this.fileName, this.arch, this.alignment, this.passed);
}

List<AlignmentResult> checkFile(String path, String arch) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  final data = ByteData.view(bytes.buffer);
  final results = <AlignmentResult>[];

  if (bytes.length < 4 || bytes[0] != 0x7f || bytes[1] != 0x45 || bytes[2] != 0x4c || bytes[3] != 0x46) {
    return results;
  }

  final cls = bytes[4];
  final endian = bytes[5] == 1 ? Endian.little : Endian.big;
  int minAlign = 999;

  if (cls == 2) {
    final phoff = data.getUint64(32, endian);
    final phesz = data.getUint16(54, endian);
    final phn = data.getUint16(56, endian);

    for (int i = 0; i < phn; i++) {
      final ph = phoff + (i * phesz);
      if (data.getUint32(ph, endian) == PT_LOAD) {
        final align = data.getUint64(ph + 48, endian);
        int power = 0;
        int val = align.toInt();
        while (val > 1) {
          val >>= 1;
          power++;
        }
        if (power < minAlign) minAlign = power;
      }
    }
  } else if (cls == 1) {
    final phoff = data.getUint32(28, endian);
    final phesz = data.getUint16(42, endian);
    final phn = data.getUint16(44, endian);

    for (int i = 0; i < phn; i++) {
      final ph = phoff + (i * phesz);
      if (data.getUint32(ph, endian) == PT_LOAD) {
        final align = data.getUint32(ph + 28, endian);
        int power = 0;
        int val = align;
        while (val > 1) {
          val >>= 1;
          power++;
        }
        if (power < minAlign) minAlign = power;
      }
    }
  }

  if (minAlign != 999) {
    final name = path.split(Platform.pathSeparator).last;
    results.add(AlignmentResult(name, arch, minAlign, minAlign >= 14));
  }

  return results;
}

void main(List<String> args) {
  String targetDir = "android/app/src/main/jniLibs";

  if (args.isNotEmpty) {
    targetDir = args[0];
  }

  final dir = Directory(targetDir);
  if (!dir.existsSync()) {
    print("Directory not found: " + targetDir);
    exit(1);
  }

  print("");
  print("==========================================");
  print("  16KB PAGE SIZE ALIGNMENT CHECKER");
  print("==========================================");
  print("");

  final allResults = <AlignmentResult>[];
  int passCount = 0;
  int failCount = 0;

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.so')) {
      // Detect architecture from path
      String arch = "unknown";
      if (entity.path.contains("arm64-v8a")) {
        arch = "arm64-v8a";
      } else if (entity.path.contains("armeabi-v7a")) {
        arch = "armeabi-v7a";
      } else if (entity.path.contains("x86_64")) {
        arch = "x86_64";
      } else if (entity.path.contains("x86")) {
        arch = "x86";
      }

      final results = checkFile(entity.path, arch);
      allResults.addAll(results);
    }
  });

  if (allResults.isEmpty) {
    print("  No .so files found in: " + targetDir);
    print("");
    return;
  }

  // Group by architecture
  final archGroups = <String, List<AlignmentResult>>{};
  for (final r in allResults) {
    archGroups.putIfAbsent(r.arch, () => []).add(r);
  }

  for (final arch in archGroups.keys) {
    print("  [$arch]");
    for (final r in archGroups[arch]!) {
      final status = r.passed ? "PASS" : "FAIL";
      final icon = r.passed ? "+" : "x";
      final alignStr = "align 2**" + r.alignment.toString();
      final sizeStr = r.alignment >= 14
          ? (r.alignment == 14 ? "16KB" : (r.alignment == 16 ? "64KB" : ">16KB"))
          : "4KB";
      print("    [$icon] $status  ${r.fileName}  ($alignStr = $sizeStr)");
      if (r.passed) {
        passCount++;
      } else {
        failCount++;
      }
    }
    print("");
  }

  print("==========================================");
  print("  RESULT: $passCount passed, $failCount failed");
  print("==========================================");
  print("");

  if (failCount > 0) {
    print("  Some libraries are NOT 16KB aligned!");
    print("  Run: dart run android_16kb_patcher");
    print("  to fix them automatically.");
    print("");
    exit(1);
  } else {
    print("  All libraries are 16KB aligned!");
    print("  Your app is ready for Android 15+.");
    print("");
  }
}
