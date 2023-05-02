import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as dartImg;
import 'package:image/image.dart' as img;

class ImageManipulator {
  late final img.Image _image;

  ImageManipulator._(this._image);

  ImageManipulator(Uint8List raw) {
    _image = img.Image.fromBytes(
        width: dartImage.width,
        height: dartImage.height,
        bytes: bytes.buffer,
        numChannels = 4);
  }

  static Future<img.Image> LoadImage(dartImg.Image dartImage) async {
    final bytes = await dartImage.toByteData();
    final img.Image image = img.Image.fromBytes(
        width: dartImage.width,
        height: dartImage.height,
        bytes: bytes.buffer,
        numChannels = 4);
    return image;
  }

  Future<double> _normalize(double component) async {
    return component / 255;
  }

  Future<double> _linearize(double component) async {
    if (component <= 0.04045) {
      return component / 12.92;
    } else {
      return pow(((component + 0.055) / 1.055), 2.4) as double;
    }
  }

  Future<int> _luminance(r, g, b) async {
    return (((0.2126 * r) + (0.7152 * g) + (0.0722 * b)) * 255) as int;
  }

  Future<int> _invertedLuminance(r, g, b) async {
    return (255 - await _luminance(r, g, b));
  }

  Future<Uint8List> processImageToPrint() async {
    int imageWidth = _image.width;
    int imageHeight = _image.height;

    if (imageWidth % 8 > 0) {
      imageWidth += (imageWidth % 8);
    }

    if (imageHeight % 8 > 0) {
      imageHeight += (imageHeight % 8);
    }

    int octetsInLine = (imageWidth / 8) as int;
    Uint8List result = new Uint8List((imageWidth * imageHeight / 8) as int);
    for (int y = 0; y < imageHeight; y++) {
      for (int x = 0; x < octetsInLine; x++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          if (x + bit < _image.width) {
            byte = byte << 1;
            Pixel pixel = _image.getPixel(x + bit, y);
            int luminance = await _invertedLuminance(
                await _linearize(await _normalize(pixel.r)),
                await _linearize(await _normalize(pixel.g)),
                await _linearize(await _normalize(pixel.b)));
            if (luminance > 0x7F) {
              byte |= 1;
            }
          }
        }
        result.add(byte);
      }
    }
    return result;
  }
}
