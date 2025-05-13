import 'dart:async';
import 'package:flutter/material.dart';

class HoldToConfirmButton extends StatefulWidget {
  final Duration holdDuration;
  final VoidCallback onConfirmed;

  const HoldToConfirmButton({
    Key? key,
    required this.holdDuration,
    required this.onConfirmed,
  }) : super(key: key);

  @override
  _HoldToConfirmButtonState createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  Timer? _timer;
  bool _isHolding = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _pulseController.repeat(reverse: true);
  }

  void _startProgress() {
    _isHolding = true;
    _pulseController.stop();
    final totalMs = widget.holdDuration.inMilliseconds;
    const interval = Duration(milliseconds: 20);

    _timer = Timer.periodic(interval, (timer) {
      setState(() {
        _progress += interval.inMilliseconds / totalMs;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isHolding = false;
          _timer?.cancel();
          widget.onConfirmed(); // Trigger confirmation
        }
      });
    });
  }

  void _cancelProgress() {
    if (_isHolding) {
      _timer?.cancel();
      setState(() {
        _progress = 0.0;
        _isHolding = false;
      });
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define gradient colors
    final baseColor = Colors.blue.shade800;
    final progressColor = Colors.blue.shade600;
    final highlightColor = Colors.blue.shade400;

    return Transform.scale(
      scale: _isHolding ? 1.0 : _pulseAnimation.value,
      child: GestureDetector(
        onLongPressStart: (_) => _startProgress(),
        onLongPressEnd: (_) => _cancelProgress(),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 3),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Base container
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [baseColor, progressColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                
                // Progress bar
                AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  width: MediaQuery.of(context).size.width * _progress,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [progressColor, highlightColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                
                // Text
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isHolding)
                        Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      if (!_isHolding)
                        SizedBox(width: 8),
                      Text(
                        _progress < 1.0 
                          ? (_isHolding ? "Hold to Complete..." : "Hold to Activate") 
                          : "Activated!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Progress dots on the side
                if (_isHolding)
                  Positioned(
                    right: 20,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
