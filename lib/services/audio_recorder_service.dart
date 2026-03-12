import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;
  bool _isPaused = false;

  bool get isPaused => _isPaused;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> start(String filePath) async {
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _isPaused = false;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
      ),
      path: filePath,
    );
  }

  Future<void> pause() async {
    if (!_isPaused) {
      await _recorder.pause();
      _pauseTime = DateTime.now();
      _isPaused = true;
    }
  }

  Future<void> resume() async {
    if (_isPaused) {
      if (_pauseTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseTime!);
      }
      await _recorder.resume();
      _isPaused = false;
    }
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    _isPaused = false;
    return path;
  }

  /// Returns the elapsed recording time (excluding pauses).
  Duration getElapsedDuration() {
    if (_startTime == null) return Duration.zero;
    final now = DateTime.now();
    final total = now.difference(_startTime!);
    final currentPause =
        _isPaused && _pauseTime != null
            ? now.difference(_pauseTime!)
            : Duration.zero;
    return total - _pausedDuration - currentPause;
  }

  Future<Amplitude> getAmplitude() async {
    return await _recorder.getAmplitude();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
