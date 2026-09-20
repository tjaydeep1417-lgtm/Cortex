import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class OCRService {
  static Future<String> extractText(String imagePath) async {
    try {
      // Compress the camera image
      final compressedPath = '${imagePath}_compressed.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        compressedPath,
        quality: 60,
        minWidth: 1600,
        minHeight: 1600,
      );

      if (compressedFile == null) {
        return 'Could not compress image.';
      }

      // Check compressed file size
      final fileSize = await File(compressedFile.path).length();
      final sizeInMB = fileSize / (1024 * 1024);

      print('Compressed image size: ${sizeInMB.toStringAsFixed(2)} MB');

      if (fileSize > 1.5 * 1024 * 1024) {
        return 'Image is still too large: ${sizeInMB.toStringAsFixed(2)} MB';
      }

      // OCR.space API
      final url = Uri.parse('https://api.ocr.space/parse/image');

      final request = http.MultipartRequest('POST', url);

      request.headers['apikey'] = 'API Key for ocr';

      request.fields['OCREngine'] = '3';
      request.fields['language'] = 'auto';

      request.files.add(
        await http.MultipartFile.fromPath('file', compressedFile.path),
      );

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      print('OCR STATUS: ${response.statusCode}');
      print('OCR RESPONSE: $responseBody');

      final data = jsonDecode(responseBody);

      if (data['IsErroredOnProcessing'] == true) {
        return 'OCR Error:\n${data['ErrorMessage']}\n${data['ErrorDetails']}';
      }

      if (data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty) {
        final text = data['ParsedResults'][0]['ParsedText'];

        if (text != null && text.toString().trim().isNotEmpty) {
          return text.toString();
        }

        return 'OCR worked, but no text was detected.';
      }

      return 'No OCR result returned.';
    } catch (e) {
      return 'OCR Error: $e';
    }
  }
}
