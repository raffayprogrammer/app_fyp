import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FaceBlurService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  /// Runs ML Kit face detection on [input] and draws a solid black rectangle
  /// over every detected face. Returns a new XFile on the filesystem, or the
  /// original if no faces were found or processing failed.
  static Future<XFile> blurFaces(XFile input) async {
    try {
      final faces = await _detector.processImage(
        InputImage.fromFile(File(input.path)),
      );
      if (faces.isEmpty) return input;

      final bytes = await input.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return input;

      decoded = img.bakeOrientation(decoded);

      for (final face in faces) {
        final box = face.boundingBox;
        final pad = box.width * 0.15;
        final x1 = (box.left - pad).clamp(0, decoded.width - 1).toInt();
        final y1 = (box.top - pad).clamp(0, decoded.height - 1).toInt();
        final x2 = (box.right + pad).clamp(0, decoded.width - 1).toInt();
        final y2 = (box.bottom + pad).clamp(0, decoded.height - 1).toInt();

        img.fillRect(
          decoded,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: img.ColorRgb8(0, 0, 0),
        );
      }

      final outBytes = img.encodeJpg(decoded, quality: 85);
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/blurred_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(outBytes);
      return XFile(path);
    } catch (_) {
      return input;
    }
  }
}
