import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import '../../alerts/custom_alerts.dart';

class TranscriptPDFHandler {
  static Future<void> downloadAndOpenTranscript(BuildContext context, int studentId) async {
    try {
      // Show loading dialog
      CustomAlert.loading(context, 'WAIT','Preparing transcript...');

      // Create LMS directory if it doesn't exist
      Directory lmsDir = Directory('/storage/emulated/0/LMS');
      if (!await lmsDir.exists()) {
        await lmsDir.create(recursive: true);
      }

      // Generate file name and path
      String fileName = 'Transcript_$studentId.pdf';
      String filePath = '${lmsDir.path}/$fileName';

      // Download the PDF
      final response = await Dio().get(
        '${ApiConfig.apiBaseUrl}Students/TranscriptPDF?student_id=$studentId',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Save the file
      File file = File(filePath);
      await file.writeAsBytes(response.data);

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      CustomAlert.success(context, 'Success \n Transcript downloaded successfully');
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      CustomAlert.error(context, 'Error', 'Failed to download transcript: ${e.toString()}');
    }
  }

  static Future<void> shareTranscript(BuildContext context, int studentId) async {
    try {
      // Show loading dialog
      CustomAlert.loading(context,'Wait', 'Preparing transcript for sharing...');

      // Create temporary directory
      final tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/Transcript_$studentId.pdf';

      // Download the PDF to temp location
      final response = await Dio().get(
        '${ApiConfig.apiBaseUrl}Students/TranscriptPDF?student_id=$studentId',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Save to temp file
      File file = File(tempPath);
      await file.writeAsBytes(response.data);

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Share the file
      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'application/pdf')],
        text: 'My Academic Transcript',
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      CustomAlert.error(context, 'Error', 'Failed to share transcript: ${e.toString()}');
    }
  }
}