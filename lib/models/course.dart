class Course {
  final String id;
  final String name;
  final String courseCode;
  final int colorValue;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.name,
    required this.courseCode,
    required this.colorValue,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'courseCode': courseCode,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      name: map['name'] as String,
      courseCode: map['courseCode'] as String,
      colorValue: map['colorValue'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Course copyWith({String? name, String? courseCode, int? colorValue}) {
    return Course(
      id: id,
      name: name ?? this.name,
      courseCode: courseCode ?? this.courseCode,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }
}
