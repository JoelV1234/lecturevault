import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import '../models/slide_marker.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lecturevault.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        courseCode TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lectures (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        title TEXT NOT NULL,
        audioPath TEXT NOT NULL,
        slidePath TEXT,
        durationMs INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        notes TEXT DEFAULT '',
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE slide_markers (
        id TEXT PRIMARY KEY,
        lectureId TEXT NOT NULL,
        pageNumber INTEGER NOT NULL,
        timestampMs INTEGER NOT NULL,
        FOREIGN KEY (lectureId) REFERENCES lectures (id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Course CRUD ──

  Future<void> insertCourse(Course course) async {
    final db = await database;
    await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Course>> getCourses() async {
    final db = await database;
    final maps = await db.query('courses', orderBy: 'createdAt DESC');
    return maps.map((map) => Course.fromMap(map)).toList();
  }

  Future<void> updateCourse(Course course) async {
    final db = await database;
    await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<void> deleteCourse(String id) async {
    final db = await database;
    // Delete associated lectures and markers first
    final lectures = await getLecturesForCourse(id);
    for (final lecture in lectures) {
      await deleteLecture(lecture.id);
    }
    await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  // ── Lecture CRUD ──

  Future<void> insertLecture(Lecture lecture) async {
    final db = await database;
    await db.insert(
      'lectures',
      lecture.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Lecture>> getLecturesForCourse(String courseId) async {
    final db = await database;
    final maps = await db.query(
      'lectures',
      where: 'courseId = ?',
      whereArgs: [courseId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Lecture.fromMap(map)).toList();
  }

  Future<List<Lecture>> getRecentLectures({int limit = 5}) async {
    final db = await database;
    final maps = await db.query(
      'lectures',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((map) => Lecture.fromMap(map)).toList();
  }

  Future<void> updateLecture(Lecture lecture) async {
    final db = await database;
    await db.update(
      'lectures',
      lecture.toMap(),
      where: 'id = ?',
      whereArgs: [lecture.id],
    );
  }

  Future<void> deleteLecture(String id) async {
    final db = await database;
    await db.delete('slide_markers', where: 'lectureId = ?', whereArgs: [id]);
    await db.delete('lectures', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getLectureCountForCourse(String courseId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lectures WHERE courseId = ?',
      [courseId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── SlideMarker CRUD ──

  Future<void> insertSlideMarker(SlideMarker marker) async {
    final db = await database;
    await db.insert(
      'slide_markers',
      marker.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertSlideMarkers(List<SlideMarker> markers) async {
    final db = await database;
    final batch = db.batch();
    for (final marker in markers) {
      batch.insert(
        'slide_markers',
        marker.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SlideMarker>> getMarkersForLecture(String lectureId) async {
    final db = await database;
    final maps = await db.query(
      'slide_markers',
      where: 'lectureId = ?',
      whereArgs: [lectureId],
      orderBy: 'timestampMs ASC',
    );
    return maps.map((map) => SlideMarker.fromMap(map)).toList();
  }

  Future<void> deleteMarkersForLecture(String lectureId) async {
    final db = await database;
    await db.delete(
      'slide_markers',
      where: 'lectureId = ?',
      whereArgs: [lectureId],
    );
  }

  // ── Utility ──

  Future<Course?> getCourseById(String id) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }
}
