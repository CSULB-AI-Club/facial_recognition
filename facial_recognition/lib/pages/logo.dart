import 'package:facial_recognition/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

void main() => runApp(MaterialApp(home: BlinkeyReveal()));

class BlinkeyReveal extends StatefulWidget {
  @override
  _BlinkeyRevealState createState() => _BlinkeyRevealState();
}

class _BlinkeyRevealState extends State<BlinkeyReveal> with TickerProviderStateMixin {
  bool riveFinished = false;
  List<bool> _visibleLetters = List.generate(7, (_) => false); // 7 letters in "Blinkey"
  double _riveOffsetX = 68.0;

void _startTextReveal() async {
  const stepOffset = -10.0; // pixels to move left for each letter

  for (int i = 0; i < _visibleLetters.length; i++) {
    await Future.delayed(Duration(milliseconds: 200));
    setState(() {
      _visibleLetters[i] = true;
      _riveOffsetX += stepOffset;
    });
  }

  // Wait a bit before navigating to login
  await Future.delayed(Duration(seconds: 2));
  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LogIn()),
    );
  }
}


  void _handleRiveStop() {
    if (!riveFinished) {
      riveFinished = true;
      _startTextReveal();
    }
  }

  @override
  void initState() {
    super.initState();

    // Fallback in case animation doesn't fire its callback
    Future.delayed(Duration(seconds: 3), () {
      if (!riveFinished) {
        //print('>> Fallback triggered');
        _handleRiveStop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(30, 90, 112, 1),
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              transform: Matrix4.translationValues(_riveOffsetX, 0, 0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: RiveAnimation.asset(
                  'assets/icons/eye_animation.riv',
                  onInit: (artboard) {
                    //print('>> Rive loaded');
                    final controller = OneShotAnimation(
                      'Timeline 1', // Replace with your actual animation name
                      autoplay: true,
                    );

                    controller.isActiveChanged.addListener(() {
                      if (!controller.isActive) {
                        _handleRiveStop();
                      }
                    });

                    artboard.addController(controller);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate('Blinkey'.length, (i) {
                return AnimatedOpacity(
                  opacity: _visibleLetters[i] ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    'Blinkey'[i],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              
            ),
          ],
        ),
      ),

    );
    
  }
}
















