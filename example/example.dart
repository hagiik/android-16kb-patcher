import 'dart:io';
import 'dart:typed_data';

const int _ptLoad = 1;

/// Patches an ELF .so file to use 16KB page alignment,
/// required for Android 15 and Google Play compliance.
///
/// Usage:
/// ```
/// dart run android_16kb_patcher path/to/lib.so
/// dart run android_16kb_patcher path/to/libs/
/// ```
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart example/example.dart <file.so | directory>');
    exit(1);
  }

  final target = args[0];
  final entity = FileSystemEntity.typeSync(target);

  if (entity == FileSystemEntityType.file) {
    _patchFile(target);
  } else if (entity == FileSystemEntityType.directory) {
    final soFiles = Directory(target)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.so'));

    for (final file in soFiles) {
      _patchFile(file.path);
    }
  } else {
    print('Error: "$target" is not a file or directory.');
    exit(1);
  }
}

void _patchFile(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  final data = ByteData.view(bytes.buffer);

  if (bytes.length < 4 ||
      bytes[0] != 0x7f ||
      bytes[1] != 0x45 ||
      bytes[2] != 0x4c ||
      bytes[3] != 0x46) {
    print('Skipped (not ELF): $path');
    return;
  }

  final cls = bytes[4];
  final endian = bytes[5] == 1 ? Endian.little : Endian.big;
  bool patched = false;

  if (cls == 2) {
    // 64-bit ELF
    final phoff = data.getUint64(32, endian);
    final phesz = data.getUint16(54, endian);
    final phn = data.getUint16(56, endian);
    for (int i = 0; i < phn; i++) {
      final ph = phoff + (i * phesz);
      if (data.getUint32(ph, endian) == _ptLoad) {
        final o = ph + 48;
        if (data.getUint64(o, endian) < 0x4000) {
          data.setUint64(o, 0x4000, endian);
          patched = true;
        }
      }
    }
  } else if (cls == 1) {
    // 32-bit ELF
    final phoff = data.getUint32(28, endian);
    final phesz = data.getUint16(42, endian);
    final phn = data.getUint16(44, endian);
    for (int i = 0; i < phn; i++) {
      final ph = phoff + (i * phesz);
      if (data.getUint32(ph, endian) == _ptLoad) {
        final o = ph + 28;
        if (data.getUint32(o, endian) < 0x4000) {
          data.setUint32(o, 0x4000, endian);
          patched = true;
        }
      }
    }
  }

  if (patched) {
    file.writeAsBytesSync(bytes);
    print('Patched: $path');
  } else {
    print('Already aligned (skipped): $path');
  }
}
