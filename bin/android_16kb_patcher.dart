import 'dart:io';
import 'dart:typed_data';

const int PT_LOAD = 1;

void patch(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  final data = ByteData.view(bytes.buffer);

  // Check ELF magic
  if (bytes.length < 4 || bytes[0] != 0x7f || bytes[1] != 0x45 || bytes[2] != 0x4c || bytes[3] != 0x46) {
    return;
  }

  final cls = bytes[4]; // 1 = 32-bit, 2 = 64-bit
  final endian = bytes[5] == 1 ? Endian.little : Endian.big;
  bool patched = false;

  if (cls == 2) { // 64-bit
    final phoff = data.getUint64(32, endian);
    final phesz = data.getUint16(54, endian);
    final phn = data.getUint16(56, endian);

    for (int i = 0; i < phn; i++) {
      final ph = phoff + (i * phesz);
      if (data.getUint32(ph, endian) == PT_LOAD) {
        final o = ph + 48;
        final align = data.getUint64(o, endian);
        if (align < 0x4000) {
          data.setUint64(o, 0x4000, endian);
          patched = true;
        }
      }
    }
  } else if (cls == 1) { // 32-bit
    final phoff = data.getUint32(28, endian);
    final phesz = data.getUint16(42, endian);
    final phn = data.getUint16(44, endian);

    for (int i = 0; i < phn; i++) {
      final ph = phoff + (i * phesz);
      if (data.getUint32(ph, endian) == PT_LOAD) {
        final o = ph + 28;
        final align = data.getUint32(o, endian);
        if (align < 0x4000) {
          data.setUint32(o, 0x4000, endian);
          patched = true;
        }
      }
    }
  }

  if (patched) {
    file.writeAsBytesSync(bytes);
    print('  patched: ${path.split(Platform.pathSeparator).last}');
  }
}

void main(List<String> args) {
  String targetDir = "android/app/src/main/jniLibs";
  
  if (args.isNotEmpty) {
    targetDir = args[0];
  } else {
    print("No directory provided. Defaulting to: " + targetDir);
  }

  final dir = Directory(targetDir);
  if (!dir.existsSync()) {
    print("Directory not found: " + targetDir);
    exit(1);
  }

  print('Scanning ' + targetDir + ' ...');
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.so')) {
      patch(entity.path);
    }
  });
  print('Done.');
}
