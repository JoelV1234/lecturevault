import 'package:flutter/material.dart';

class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final String elapsedTime;
  final VoidCallback onRecord;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.elapsedTime,
    required this.onRecord,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isRecording && !isPaused
                      ? Colors.red.withOpacity(0.3)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecording && !isPaused)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                elapsedTime,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRecording) ...[
              // Stop button
              _ControlButton(
                icon: Icons.stop_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 56,
                onTap: onStop,
                label: 'Stop',
              ),
              const SizedBox(width: 32),
              // Pause / Resume button
              _ControlButton(
                icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 72,
                onTap: isPaused ? onResume : onPause,
                label: isPaused ? 'Resume' : 'Pause',
              ),
            ] else ...[
              // Record button
              _ControlButton(
                icon: Icons.mic_rounded,
                color: Colors.red,
                size: 80,
                onTap: onRecord,
                label: 'Record',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final String label;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color.withOpacity(0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: size * 0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
