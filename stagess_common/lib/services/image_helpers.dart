import 'dart:typed_data';
import 'package:image/image.dart';

class ImageHelpers {
  static const logoWidth = 190;
  static const logoHeight = 80;

  static Future<Uint8List> resizeImage(
    Uint8List imageData, {
    required int? width,
    required int? height,
  }) async {
    // Decode the image from the Uint8List
    Image? image = decodeImage(imageData);
    if (image == null) throw Exception('Failed to decode image');

    // Resize the image
    Image resizedImage = copyResize(image, width: width, height: height);
    // Encode the resized image back to Uint8List
    Uint8List resizedImageData = encodePng(resizedImage);
    if (resizedImageData.isEmpty) {
      throw Exception('Failed to encode resized image');
    }
    // Return the resized image data
    return resizedImageData;
  }
}
