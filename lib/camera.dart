import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> openCamera() async {
  // Request camera permission
  var status = await Permission.camera.request();

  if (status.isGranted) {
    try {
      final ImagePicker picker = ImagePicker();

      // Open camera and take a photo
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        debugPrint('Image captured: ${image.path}');
      }

      // Give the image back to screen.dart
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  } else if (status.isPermanentlyDenied) {
    await openAppSettings();
    return null;
  } else {
    debugPrint('Camera permission denied');
    return null;
  }
}
