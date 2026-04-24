import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Runs Google ML Kit face detection on the given image.
  /// Returns a summary describing how many faces were found and a verification
  /// verdict (true if exactly one face with high confidence was found).
  static Future<FaceCheckResult> verifyFace(File image) async {
    final input = InputImage.fromFile(image);
    final faces = await _detector.processImage(input);

    if (faces.isEmpty) {
      return FaceCheckResult(
        verified: false,
        faceCount: 0,
        reason: 'No face detected. Make sure your face is clearly visible.',
      );
    }

    if (faces.length > 1) {
      return FaceCheckResult(
        verified: false,
        faceCount: faces.length,
        reason:
            'Multiple faces detected. Only the reporter should be in the photo.',
      );
    }

    final face = faces.first;
    final smileProb = face.smilingProbability ?? 0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1;

    if (leftEyeOpen < 0.2 && rightEyeOpen < 0.2) {
      return FaceCheckResult(
        verified: false,
        faceCount: 1,
        reason: 'Eyes appear closed. Take a clear selfie with eyes open.',
      );
    }

    return FaceCheckResult(
      verified: true,
      faceCount: 1,
      reason: 'Face verified.',
      smilingProbability: smileProb,
    );
  }

  static void dispose() {
    _detector.close();
  }
}

class FaceCheckResult {
  final bool verified;
  final int faceCount;
  final String reason;
  final double? smilingProbability;

  FaceCheckResult({
    required this.verified,
    required this.faceCount,
    required this.reason,
    this.smilingProbability,
  });
}
