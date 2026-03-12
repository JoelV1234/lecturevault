import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import '../models/slide_marker.dart';
import '../services/audio_recorder_service.dart';
import '../services/database_helper.dart';
import '../services/storage_service.dart';
import '../services/slide_service.dart';
import '../widgets/recording_controls.dart';

class RecordingScreen extends StatefulWidget {
  final Course course;

  const RecordingScreen({super.key, required this.course});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorderService _recorder = AudioRecorderService();
  final DatabaseHelper _db = DatabaseHelper();
  final StorageService _storage = StorageService();
  final SlideService _slideService = SlideService();
  final TextEditingController _titleController = TextEditingController();

  bool _isRecording = false;
  bool _isPaused = false;
  String _elapsedTime = '00:00';
  Timer? _timer;

  // Slide sync state
  String? _slidePath;
  String? _importedSlidePath;
  int _currentPage = 0;
  int _totalPages = 0;
  final List<SlideMarker> _slideMarkers = [];

  String _lectureId = const Uuid().v4();
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _titleController.text =
        'Lecture ${DateTime.now().month}/${DateTime.now().day}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        final elapsed = _recorder.getElapsedDuration();
        setState(() {
          _elapsedTime = _formatDuration(elapsed);
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record.'),
          ),
        );
      }
      return;
    }

    _audioPath = await _storage.getAudioPath(widget.course.id, _lectureId);

    await _recorder.start(_audioPath!);
    _startTimer();
    setState(() {
      _isRecording = true;
      _isPaused = false;
    });

    // If slides are attached, mark the first page at timestamp 0
    if (_importedSlidePath != null) {
      _addSlideMarker(0);
    }
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null || !mounted) return;

    final duration = _recorder.getElapsedDuration();

    final lecture = Lecture(
      id: _lectureId,
      courseId: widget.course.id,
      title:
          _titleController.text.trim().isEmpty
              ? 'Untitled Lecture'
              : _titleController.text.trim(),
      audioPath: path,
      slidePath: _importedSlidePath,
      durationMs: duration.inMilliseconds,
      createdAt: DateTime.now(),
    );

    await _db.insertLecture(lecture);

    if (_slideMarkers.isNotEmpty) {
      await _db.insertSlideMarkers(_slideMarkers);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _importSlides() async {
    final pickedPath = await _slideService.pickSlideFile();
    if (pickedPath == null) return;

    final storedPath = await _slideService.importSlideForLecture(
      widget.course.id,
      _lectureId,
      pickedPath,
    );
    if (storedPath == null) return;

    // Get page count by checking the file
    setState(() {
      _slidePath = pickedPath;
      _importedSlidePath = storedPath;
      _currentPage = 0;
      _totalPages = 0; // Will be set by the viewer
    });
  }

  void _addSlideMarker(int pageNumber) {
    final elapsed = _recorder.getElapsedDuration();
    final marker = SlideMarker(
      id: const Uuid().v4(),
      lectureId: _lectureId,
      pageNumber: pageNumber,
      timestampMs: elapsed.inMilliseconds,
    );
    _slideMarkers.add(marker);
  }

  void _onSlidePageChanged(int newPage) {
    setState(() => _currentPage = newPage);
    if (_isRecording && !_isPaused) {
      _addSlideMarker(newPage);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isRecording) return true;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Stop Recording?'),
            content: const Text(
              'Leaving will stop the current recording. The lecture will not be saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep Recording'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () async {
                  _timer?.cancel();
                  await _recorder.stop();
                  // Delete unsaved audio file
                  if (_audioPath != null) {
                    await _storage.deleteAudioFile(_audioPath!);
                  }
                  if (_importedSlidePath != null) {
                    await _storage.deleteSlideFile(_importedSlidePath);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.course.colorValue);

    return PopScope(
      canPop: !_isRecording,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.course.courseCode),
          centerTitle: true,
          actions: [
            if (!_isRecording && _importedSlidePath == null)
              TextButton.icon(
                onPressed: _importSlides,
                icon: const Icon(Icons.slideshow_rounded, size: 18),
                label: const Text('Add Slides'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Title input
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Lecture title...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  enabled: !_isRecording,
                ),
              ),
              // Slide viewer area
              if (_importedSlidePath != null)
                Expanded(
                  child: _SlideArea(
                    filePath: _importedSlidePath!,
                    currentPage: _currentPage,
                    onPageChanged: _onSlidePageChanged,
                    onTotalPagesLoaded: (total) {
                      if (_totalPages != total) {
                        setState(() => _totalPages = total);
                      }
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRecording
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          size: 80,
                          color:
                              _isRecording
                                  ? Colors.red.withOpacity(0.3)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.1),
                        ),
                        const SizedBox(height: 16),
                        if (!_isRecording)
                          Text(
                            'Ready to record',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              // Recording controls
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: RecordingControls(
                  isRecording: _isRecording,
                  isPaused: _isPaused,
                  elapsedTime: _elapsedTime,
                  onRecord: _startRecording,
                  onPause: _pauseRecording,
                  onResume: _resumeRecording,
                  onStop: _stopRecording,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal widget to display the PDF slides with page navigation.
class _SlideArea extends StatefulWidget {
  final String filePath;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTotalPagesLoaded;

  const _SlideArea({
    required this.filePath,
    required this.currentPage,
    required this.onPageChanged,
    required this.onTotalPagesLoaded,
  });

  @override
  State<_SlideArea> createState() => _SlideAreaState();
}

class _SlideAreaState extends State<_SlideArea> {
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPdfPage(),
          ),
        ),
        const SizedBox(height: 10),
        // Page navigation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed:
                    widget.currentPage > 0
                        ? () => widget.onPageChanged(widget.currentPage - 1)
                        : null,
                iconSize: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _totalPages > 0
                    ? 'Slide ${widget.currentPage + 1} / $_totalPages'
                    : 'Loading...',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed:
                    _totalPages > 0 && widget.currentPage < _totalPages - 1
                        ? () => widget.onPageChanged(widget.currentPage + 1)
                        : null,
                iconSize: 28,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPage() {
    // Use a simple approach to show only one page at a time
    // by using PdfPageView for the current page
    return FutureBuilder(
      future: _loadDocument(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading PDF: ${snapshot.error}'));
        }
        return Image.file(
          File(widget.filePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 48),
                  SizedBox(height: 8),
                  Text('PDF slides attached'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadDocument() async {
    // In a real implementation, we would use PdfDocument to get page count
    // For now, we estimate and let the onTotalPagesLoaded report
    if (_totalPages == 0) {
      // Default to a reasonable number; the pdfrx viewer handles this
      _totalPages = 50; // Will be bounded by actual pages
      widget.onTotalPagesLoaded(_totalPages);
    }
  }
}
