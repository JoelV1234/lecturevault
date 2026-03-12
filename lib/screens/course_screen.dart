import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import '../services/database_helper.dart';
import '../widgets/lecture_card.dart';
import 'recording_screen.dart';
import 'playback_screen.dart';

class CourseScreen extends StatefulWidget {
  final Course course;

  const CourseScreen({super.key, required this.course});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Lecture> _lectures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLectures();
  }

  Future<void> _loadLectures() async {
    setState(() => _isLoading = true);
    final lectures = await _db.getLecturesForCourse(widget.course.id);
    setState(() {
      _lectures = lectures;
      _isLoading = false;
    });
  }

  void _showDeleteLectureDialog(Lecture lecture) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Lecture?'),
            content: Text(
              'This will permanently delete "${lecture.title}" and its recording.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () async {
                  await _db.deleteLecture(lecture.id);
                  if (mounted) Navigator.pop(ctx);
                  _loadLectures();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.course.colorValue);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.course.name),
                Text(
                  widget.course.courseCode,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_lectures.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_off_rounded,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No lectures recorded',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the record button to start',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final lecture = _lectures[index];
                  return Dismissible(
                    key: Key(lecture.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      _showDeleteLectureDialog(lecture);
                      return false;
                    },
                    child: LectureCard(
                      lecture: lecture,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaybackScreen(lecture: lecture),
                          ),
                        );
                        _loadLectures();
                      },
                    ),
                  );
                }, childCount: _lectures.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordingScreen(course: widget.course),
            ),
          );
          _loadLectures();
        },
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Record Lecture'),
      ),
    );
  }
}
