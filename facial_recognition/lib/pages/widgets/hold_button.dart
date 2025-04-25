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

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> {
  double _progress = 0.0;
  Timer? _timer;
  bool _isHolding = false;

  void _startProgress() {
    _isHolding = true;
    final totalMs = widget.holdDuration.inMilliseconds;
    const interval = Duration(milliseconds: 20);

    _timer = Timer.periodic(interval, (timer) {
      setState(() {
        _progress += interval.inMilliseconds / totalMs;
        if (_progress >= 1.0) {
          _progress = 1.5;
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
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startProgress(),
      onLongPressEnd: (_) => _cancelProgress(),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.redAccent,
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * _progress,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromARGB(255, 203, 57, 57),
            ),
          ),
          Center(
            child: Text(
              _progress < 1.0 ? "Hold to Activate" : "Activated!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}
