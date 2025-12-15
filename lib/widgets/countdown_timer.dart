import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showLabels;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.textStyle,
    this.backgroundColor,
    this.textColor,
    this.showLabels = true,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    if (now.isBefore(widget.endTime)) {
      _remainingTime = widget.endTime.difference(now);
    } else {
      _remainingTime = Duration.zero;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '$days يوم ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remainingTime <= Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.grey[300]
            : widget.backgroundColor ?? Colors.pink[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired ? Colors.grey : Colors.pink.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: isExpired ? Colors.grey : Colors.pink,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'انتهى العرض' : _formatDuration(_remainingTime),
            style:
                widget.textStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isExpired
                      ? Colors.grey
                      : widget.textColor ?? Colors.pink[800],
                ),
          ),
        ],
      ),
    );
  }
}
