import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

/// Service for processing various file types to extract text content.
/// Supports TXT, PDF, DOCX, PPTX, and images with OCR.
class FileProcessingService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick a file from device storage.
  Future<FilePickerResult?> pickFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'docx', 'pptx', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
  }

  /// Pick an image from camera or gallery.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _imagePicker.pickImage(source: source);
  }

  /// Extract text from a file based on its type.
  Future<String> extractTextFromFile(FilePickerResult result) async {
    if (result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final file = result.files.first;
    final path = file.path;

    if (path == null) {
      throw Exception('File path is null');
    }

    final extension = file.extension?.toLowerCase() ?? '';

    switch (extension) {
      case 'txt':
        return await _extractFromTxt(path);
      case 'pdf':
        return await _extractFromPdf(path);
      case 'docx':
        return await _extractFromDocx(path);
      case 'pptx':
        return await _extractFromPptx(path);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return await _extractFromImage(path);
      default:
        throw Exception('Unsupported file type: $extension');
    }
  }

  /// Extract text from a TXT file.
  Future<String> _extractFromTxt(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }
    return await file.readAsString();
  }

  /// Extract text from a PDF file.
  Future<String> _extractFromPdf(String path) async {
    // Note: Full PDF parsing requires additional dependencies.
    // For now, we'll return a placeholder and recommend using a PDF parsing library.
    // In production, consider using syncfusion_flutter_pdf or similar.
    throw Exception('PDF parsing requires additional setup. Please use TXT files or images for now.');
  }

  /// Extract text from a DOCX file.
  Future<String> _extractFromDocx(String path) async {
    // Note: DOCX parsing requires additional dependencies.
    // For now, we'll return a placeholder.
    throw Exception('DOCX parsing requires additional setup. Please use TXT files or images for now.');
  }

  /// Extract text from a PPTX file.
  Future<String> _extractFromPptx(String path) async {
    // Note: PPTX parsing requires additional dependencies.
    // For now, we'll return a placeholder.
    throw Exception('PPTX parsing requires additional setup. Please use TXT files or images for now.');
  }

  /// Extract text from an image using OCR.
  Future<String> _extractFromImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await textRecognizer.close();
    }
  }

  /// Extract text from an XFile (image picker result).
  Future<String> extractTextFromImage(XFile imageFile) async {
    return await _extractFromImage(imageFile.path);
  }

  /// Get a human-readable file type name.
  String getFileTypeName(String extension) {
    switch (extension.toLowerCase()) {
      case 'txt':
        return 'Text File';
      case 'pdf':
        return 'PDF Document';
      case 'docx':
        return 'Word Document';
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'Image';
      default:
        return 'Unknown File';
    }
  }
}
