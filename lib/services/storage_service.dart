import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final lectureDir = Directory(p.join(dir.path, 'lecturevault'));
    if (!await lectureDir.exists()) {
      await lectureDir.create(recursive: true);
    }
    return lectureDir;
  }

  /// Returns the directory for a specific course, creating it if needed.
  Future<Directory> getCourseDirectory(String courseId) async {
    final base = await _appDir;
    final courseDir = Directory(p.join(base.path, 'courses', courseId));
    if (!await courseDir.exists()) {
      await courseDir.create(recursive: true);
    }
    return courseDir;
  }

  /// Returns the path where an audio file should be saved for a lecture.
  Future<String> getAudioPath(String courseId, String lectureId) async {
    final courseDir = await getCourseDirectory(courseId);
    return p.join(courseDir.path, '${lectureId}_audio.m4a');
  }

  /// Copies an imported PDF slide deck into the course directory.
  Future<String> copySlideFile(
    String courseId,
    String lectureId,
    String sourcePath,
  ) async {
    final courseDir = await getCourseDirectory(courseId);
    final ext = p.extension(sourcePath);
    final destPath = p.join(courseDir.path, '${lectureId}_slides$ext');
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Deletes the audio file for a lecture.
  Future<void> deleteAudioFile(String audioPath) async {
    final file = File(audioPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Deletes the slide file for a lecture.
  Future<void> deleteSlideFile(String? slidePath) async {
    if (slidePath == null) return;
    final file = File(slidePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Deletes the entire course directory.
  Future<void> deleteCourseDirectory(String courseId) async {
    final courseDir = await getCourseDirectory(courseId);
    if (await courseDir.exists()) {
      await courseDir.delete(recursive: true);
    }
  }
}
