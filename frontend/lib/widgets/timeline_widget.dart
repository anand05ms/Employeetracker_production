// lib/widgets/timeline_widget.dart
// Beautiful timeline for journey/visit history (like DayTrack)

import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class TimelineItem {
  final String time;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final TimelineItemType type;
  final Map<String, dynamic>? data;
  
  TimelineItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.type,
    this.data,
  });
}

enum TimelineItemType {
  checkIn,
  checkOut,
  moving,
  stopped,
  visit,
  milestone,
}

class JourneyTimeline extends StatefulWidget {
  final List<TimelineItem> items;
  final bool showDuration;
  
  const JourneyTimeline({
    Key? key,
    required this.items,
    this.showDuration = true,
  }) : super(key: key);

  @override
  State<JourneyTimeline> createState() => _JourneyTimelineState();
}

class _JourneyTimelineState extends State<JourneyTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600 * widget.items.length),
      vsync: this,
    );
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _calculateDuration(int index) {
    if (!widget.showDuration || index >= widget.items.length - 1) {
      return null;
    }
    
    try {
      final currentTime = DateFormat('HH:mm').parse(widget.items[index].time);
      final nextTime = DateFormat('HH:mm').parse(widget.items[index + 1].time);
      
      final duration = nextTime.difference(currentTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final duration = _calculateDuration(index);
        final isFirst = index == 0;
        final isLast = index == widget.items.length - 1;
        
        // Stagger animation
        final animationDelay = index / widget.items.length;
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              animationDelay,
              (animationDelay + 0.2).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animation.value)),
                child: child,
              ),
            );
          },
          child: TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.15,
            isFirst: isFirst,
            isLast: isLast,
            indicatorStyle: IndicatorStyle(
              width: 40,
              height: 40,
              indicator: _buildIndicator(item),
              drawGap: true,
            ),
            beforeLineStyle: LineStyle(
              color: item.color.withOpacity(0.3),
              thickness: 3,
            ),
            endChild: _buildContent(item, duration),
          ),
        );
      },
    );
  }
  
  Widget _buildIndicator(TimelineItem item) {
    return Container(
      decoration: BoxDecoration(
        color: item.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          item.icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  Widget _buildContent(TimelineItem item, String? duration) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
              ),
              if (duration != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              item.subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (item.data != null) ...[
            const SizedBox(height: 12),
            _buildDataChips(item.data!),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDataChips(Map<String, dynamic> data) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: data.entries.map((entry) {
        IconData? icon;
        Color? color;
        
        // Determine icon and color based on key
        switch (entry.key.toLowerCase()) {
          case 'speed':
            icon = Icons.speed;
            color = AppTheme.info;
            break;
          case 'distance':
            icon = Icons.straighten;
            color = AppTheme.warning;
            break;
          case 'duration':
            icon = Icons.timer;
            color = AppTheme.success;
            break;
          case 'location':
            icon = Icons.location_on;
            color = AppTheme.error;
            break;
          default:
            icon = Icons.info_outline;
            color = AppTheme.grey;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '${entry.value}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Compact Timeline (for cards)
class CompactTimeline extends StatelessWidget {
  final List<TimelineItem> items;
  final int maxItems;
  
  const CompactTimeline({
    Key? key,
    required this.items,
    this.maxItems = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayItems = items.take(maxItems).toList();
    
    return Column(
      children: displayItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == displayItems.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 12),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: item.color.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// Helper to create timeline items from location data
class TimelineHelper {
  static TimelineItem fromLocation(Map<String, dynamic> location) {
    final timestamp = DateTime.parse(location['timestamp']);
    final time = DateFormat('HH:mm').format(timestamp);
    final speed = (location['speed'] as num?)?.toDouble() ?? 0.0;
    
    TimelineItemType type;
    IconData icon;
    Color color;
    String title;
    
    if (location['isCheckIn'] == true) {
      type = TimelineItemType.checkIn;
      icon = Icons.login;
      color = AppTheme.success;
      title = 'Checked In';
    } else if (location['isCheckOut'] == true) {
      type = TimelineItemType.checkOut;
      icon = Icons.logout;
      color = AppTheme.error;
      title = 'Checked Out';
    } else if (speed > 5) {
      type = TimelineItemType.moving;
      icon = Icons.directions_car;
      color = AppTheme.info;
      title = 'Moving';
    } else {
      type = TimelineItemType.stopped;
      icon = Icons.pause_circle;
      color = AppTheme.warning;
      title = 'Stopped';
    }
    
    return TimelineItem(
      time: time,
      title: title,
      subtitle: location['address'],
      icon: icon,
      color: color,
      type: type,
      data: {
        'Speed': '${speed.toStringAsFixed(0)} km/h',
        if (location['duration'] != null)
          'Duration': location['duration'],
      },
    );
  }
  
  static List<TimelineItem> fromLocationList(List<Map<String, dynamic>> locations) {
    return locations.map((loc) => fromLocation(loc)).toList();
  }
}