import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorage {
  static Future<String> saveImage(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = path.join(appDir.path, 'photos', fileName);
    
    await Directory(path.dirname(destPath)).create(recursive: true);
    await sourceFile.copy(destPath);
    return destPath;
  }
}
