import 'package:file_picker/file_picker.dart';
import 'storage_service.dart';

class SlideService {
  final StorageService _storageService = StorageService();

  /// Opens a file picker for the user to select a PDF slide deck.
  /// Returns the picked file path, or null if cancelled.
  Future<String?> pickSlideFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }
    return null;
  }

  /// Imports a slide file into the app storage for a specific lecture.
  /// Returns the new path of the copied file.
  Future<String?> importSlideForLecture(
    String courseId,
    String lectureId,
    String sourcePath,
  ) async {
    return await _storageService.copySlideFile(courseId, lectureId, sourcePath);
  }
}
