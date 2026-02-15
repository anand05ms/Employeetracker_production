// lib/widgets/playback_controls.dart
// Video-style playback controls for route replay (like BlackBuck)

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlaybackControls extends StatefulWidget {
  final bool isPlaying;
  final double currentPosition; // 0.0 to 1.0
  final double speed; // 0.5x, 1x, 2x, 5x, 10x
  final Duration totalDuration;
  final Duration currentDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final Function(double) onSeek;
  final Function(double) onSpeedChange;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PlaybackControls({
    Key? key,
    required this.isPlaying,
    required this.currentPosition,
    required this.speed,
    required this.totalDuration,
    required this.currentDuration,
    required this.onPlayPause,
    required this.onStop,
    required this.onSeek,
    required this.onSpeedChange,
    this.onPrevious,
    this.onNext,
  }) : super(key: key);

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? 160 : 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Expand/Collapse Handle
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          if (_isExpanded) ...[
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: widget.currentPosition,
                      onChanged: widget.onSeek,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(widget.currentDuration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDuration(widget.totalDuration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speed Control
                _buildSpeedControl(),

                // Previous (if available)
                if (widget.onPrevious != null)
                  _buildControlButton(
                    icon: Icons.skip_previous,
                    onPressed: widget.onPrevious!,
                    size: 32,
                  ),

                // Play/Pause
                _buildPlayPauseButton(),

                // Next (if available)
                if (widget.onNext != null)
                  _buildControlButton(
                    icon: Icons.skip_next,
                    onPressed: widget.onNext!,
                    size: 32,
                  ),

                // Stop
                _buildControlButton(
                  icon: Icons.stop,
                  onPressed: widget.onStop,
                  color: AppTheme.error,
                  size: 32,
                ),
              ],
            ),
          ] else ...[
            // Compact Mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildPlayPauseButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: widget.currentPosition,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                          minHeight: 3,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(widget.currentDuration),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${widget.speed}x',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildControlButton(
                    icon: Icons.stop,
                    onPressed: widget.onStop,
                    color: AppTheme.error,
                    size: 28,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isPlaying
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(
                        0.3 * _pulseController.value,
                      ),
                      blurRadius: 20 * _pulseController.value,
                      spreadRadius: 5 * _pulseController.value,
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: AppTheme.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              onTap: widget.onPlayPause,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double size = 24,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: color ?? Colors.grey[700],
            size: size,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedControl() {
    final speeds = [0.5, 1.0, 2.0, 5.0, 10.0];

    return PopupMenuButton<double>(
      initialValue: widget.speed,
      onSelected: widget.onSpeedChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              size: 16,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.speed}x',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return speeds.map((speed) {
          return PopupMenuItem<double>(
            value: speed,
            child: Row(
              children: [
                if (speed == widget.speed)
                  Icon(Icons.check, size: 16, color: AppTheme.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(
                  '${speed}x',
                  style: TextStyle(
                    fontWeight: speed == widget.speed
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: speed == widget.speed
                        ? AppTheme.primary
                        : Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  _getSpeedLabel(speed),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  String _getSpeedLabel(double speed) {
    if (speed <= 0.5) return 'Slow';
    if (speed <= 1.0) return 'Normal';
    if (speed <= 2.0) return 'Fast';
    if (speed <= 5.0) return 'Very Fast';
    return 'Ultra Fast';
  }
}

// Mini Playback Controls (for embedded use)
class MiniPlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final double speed;
  final String currentTime;

  const MiniPlaybackControls({
    Key? key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.speed,
    required this.currentTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppTheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPlayPause,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currentTime,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${speed}x',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
