class SlideMarker {
  final String id;
  final String lectureId;
  final int pageNumber;
  final int timestampMs;

  SlideMarker({
    required this.id,
    required this.lectureId,
    required this.pageNumber,
    required this.timestampMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lectureId': lectureId,
      'pageNumber': pageNumber,
      'timestampMs': timestampMs,
    };
  }

  factory SlideMarker.fromMap(Map<String, dynamic> map) {
    return SlideMarker(
      id: map['id'] as String,
      lectureId: map['lectureId'] as String,
      pageNumber: map['pageNumber'] as int,
      timestampMs: map['timestampMs'] as int,
    );
  }

  String get formattedTimestamp {
    final duration = Duration(milliseconds: timestampMs);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
