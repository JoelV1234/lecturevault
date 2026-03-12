import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import '../services/database_helper.dart';
import '../widgets/course_card.dart';
import '../widgets/lecture_card.dart';
import 'course_screen.dart';
import 'playback_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Course> _courses = [];
  List<Lecture> _recentLectures = [];
  Map<String, int> _lectureCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final courses = await _db.getCourses();
    final recent = await _db.getRecentLectures(limit: 5);

    final counts = <String, int>{};
    for (final course in courses) {
      counts[course.id] = await _db.getLectureCountForCourse(course.id);
    }

    setState(() {
      _courses = courses;
      _recentLectures = recent;
      _lectureCounts = counts;
      _isLoading = false;
    });
  }

  void _showAddCourseDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    int selectedColorIndex = 0;

    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
    ];

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('New Course'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Course Name',
                          hintText: 'e.g. Introduction to Psychology',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Course Code',
                          hintText: 'e.g. PSYC 100A',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Color',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children:
                            colors.asMap().entries.map((entry) {
                              final isSelected =
                                  entry.key == selectedColorIndex;
                              return GestureDetector(
                                onTap:
                                    () => setDialogState(
                                      () => selectedColorIndex = entry.key,
                                    ),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: entry.value,
                                    shape: BoxShape.circle,
                                    border:
                                        isSelected
                                            ? Border.all(
                                              color:
                                                  Theme.of(
                                                    ctx,
                                                  ).colorScheme.onSurface,
                                              width: 2.5,
                                            )
                                            : null,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final code = codeController.text.trim();
                        if (name.isEmpty || code.isEmpty) return;

                        final course = Course(
                          id: const Uuid().v4(),
                          name: name,
                          courseCode: code,
                          colorValue: colors[selectedColorIndex].value,
                          createdAt: DateTime.now(),
                        );
                        await _db.insertCourse(course);
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteCourseDialog(Course course) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Course?'),
            content: Text(
              'This will permanently delete "${course.name}" and all its lectures.',
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
                  await _db.deleteCourse(course.id);
                  if (mounted) Navigator.pop(ctx);
                  _loadData();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: const Text('LectureVault'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded),
                        onPressed: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'LectureVault',
                            applicationVersion: '1.0.0',
                            children: [
                              const Text(
                                'Seamless audio-visual synchronization for total lecture capture.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  // Recent Lectures section
                  if (_recentLectures.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Recent Lectures',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final lecture = _recentLectures[index];
                          return LectureCard(
                            lecture: lecture,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PlaybackScreen(lecture: lecture),
                                ),
                              );
                              _loadData();
                            },
                          );
                        }, childCount: _recentLectures.length),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                  // Courses section
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Courses',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_courses.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No courses yet',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first course',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
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
                          final course = _courses[index];
                          return CourseCard(
                            course: course,
                            lectureCount: _lectureCounts[course.id] ?? 0,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CourseScreen(course: course),
                                ),
                              );
                              _loadData();
                            },
                            onLongPress: () => _showDeleteCourseDialog(course),
                          );
                        }, childCount: _courses.length),
                      ),
                    ),
                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCourseDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Course'),
      ),
    );
  }
}
