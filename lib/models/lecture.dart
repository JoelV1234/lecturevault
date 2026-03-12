class Lecture {
  final String id;
  final String courseId;
  final String title;
  final String audioPath;
  final String? slidePath;
  final int durationMs;
  final DateTime createdAt;
  final String notes;

  Lecture({
    required this.id,
    required this.courseId,
    required this.title,
    required this.audioPath,
    this.slidePath,
    required this.durationMs,
    required this.createdAt,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'audioPath': audioPath,
      'slidePath': slidePath,
      'durationMs': durationMs,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Lecture.fromMap(Map<String, dynamic> map) {
    return Lecture(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      title: map['title'] as String,
      audioPath: map['audioPath'] as String,
      slidePath: map['slidePath'] as String?,
      durationMs: map['durationMs'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Lecture copyWith({
    String? title,
    String? audioPath,
    String? slidePath,
    int? durationMs,
    String? notes,
  }) {
    return Lecture(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      slidePath: slidePath ?? this.slidePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }

  String get formattedDuration {
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}
