import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileDownloader {
  static Future<String?> downloadFile({
    required String url,
    required String fileName,
    required Function(double) onProgress,
  }) async {
    // Check storage permission
    if (!await _requestPermission()) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      final dio = Dio();

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      return savePath;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }
  static Future<bool> _requestPermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}