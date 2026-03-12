import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/lecture.dart';
import '../models/slide_marker.dart';
import '../services/database_helper.dart';

class PlaybackScreen extends StatefulWidget {
  final Lecture lecture;

  const PlaybackScreen({super.key, required this.lecture});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final AudioPlayer _player = AudioPlayer();
  final DatabaseHelper _db = DatabaseHelper();

  List<SlideMarker> _markers = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  int _currentSlide = 0;
  final TextEditingController _notesController = TextEditingController();
  bool _notesEdited = false;

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.lecture.notes;
    _initPlayer();
    _loadMarkers();
  }

  Future<void> _initPlayer() async {
    await _player.setSource(DeviceFileSource(widget.lecture.audioPath));

    _positionSub = _player.onPositionChanged.listen((pos) {
      setState(() {
        _position = pos;
        _updateCurrentSlide();
      });
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      setState(() => _duration = dur);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _loadMarkers() async {
    final markers = await _db.getMarkersForLecture(widget.lecture.id);
    setState(() => _markers = markers);
  }

  void _updateCurrentSlide() {
    if (_markers.isEmpty) return;
    for (int i = _markers.length - 1; i >= 0; i--) {
      if (_position.inMilliseconds >= _markers[i].timestampMs) {
        if (_currentSlide != _markers[i].pageNumber) {
          setState(() => _currentSlide = _markers[i].pageNumber);
        }
        break;
      }
    }
  }

  void _seekToMarker(SlideMarker marker) {
    _player.seek(Duration(milliseconds: marker.timestampMs));
    setState(() => _currentSlide = marker.pageNumber);
  }

  Future<void> _saveNotes() async {
    if (_notesEdited) {
      final updated = widget.lecture.copyWith(
        notes: _notesController.text.trim(),
      );
      await _db.updateLecture(updated);
    }
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

  @override
  void dispose() {
    _saveNotes();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSlides = widget.lecture.slidePath != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lecture.title), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            // Slide viewer
            if (hasSlides)
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PdfViewer.file(
                    widget.lecture.slidePath!,
                    params: const PdfViewerParams(),
                  ),
                ),
              ),
            if (!hasSlides)
              Expanded(flex: 2, child: _buildNotesSection(context)),
            // Slide markers timeline
            if (hasSlides && _markers.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _markers.length,
                  itemBuilder: (context, index) {
                    final marker = _markers[index];
                    final isActive = _currentSlide == marker.pageNumber;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.slideshow_rounded,
                          size: 16,
                          color:
                              isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                        label: Text(
                          'Slide ${marker.pageNumber + 1} • ${marker.formattedTimestamp}',
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        onPressed: () => _seekToMarker(marker),
                        side:
                            isActive
                                ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                )
                                : null,
                      ),
                    );
                  },
                ),
              ),
            // Audio controls
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seekbar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                    ),
                    child: Slider(
                      value:
                          _duration.inMilliseconds > 0
                              ? _position.inMilliseconds.toDouble().clamp(
                                0,
                                _duration.inMilliseconds.toDouble(),
                              )
                              : 0,
                      max:
                          _duration.inMilliseconds > 0
                              ? _duration.inMilliseconds.toDouble()
                              : 1,
                      onChanged: (value) {
                        _player.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  // Time labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Play controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded),
                        iconSize: 32,
                        onPressed: () {
                          final newPos =
                              _position - const Duration(seconds: 10);
                          _player.seek(
                            newPos < Duration.zero ? Duration.zero : newPos,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            if (_isPlaying) {
                              _player.pause();
                            } else {
                              _player.resume();
                            }
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.forward_30_rounded),
                        iconSize: 32,
                        onPressed: () {
                          final newPos =
                              _position + const Duration(seconds: 30);
                          _player.seek(newPos > _duration ? _duration : newPos);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lecture Notes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Add notes about this lecture...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) => _notesEdited = true,
            ),
          ),
        ],
      ),
    );
  }
}
