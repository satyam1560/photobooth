import 'package:flutter/material.dart';

// class RollingImage extends StatefulWidget {
//   const RollingImage({super.key});

//   @override
//   _RollingImageState createState() => _RollingImageState();
// }

// class _RollingImageState extends State<RollingImage> with TickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize the AnimationController
//     _controller = AnimationController(
//       duration: const Duration(seconds: 5),
//       vsync: this,
//     )..repeat(); // The animation will repeat indefinitely
//   }

//   @override
//   void dispose() {
//     _controller.dispose(); // Dispose the controller when no longer needed
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Container(
//           width: 150,
//           height: 150,
//           color: Colors.blueAccent,
//           child: RotationTransition(
//             turns: _controller,
//             child: Image.asset('assets/background_image.jpg'), // Replace with your image asset
//           ),
//         ),
//       ),
//     );
//   }
// }

class ScrollDownImage extends StatefulWidget {
  const ScrollDownImage({super.key});

  @override
  _ScrollDownImageState createState() => _ScrollDownImageState();
}

class _ScrollDownImageState extends State<ScrollDownImage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // Define the animation, it will animate from 0 (no image shown) to 1 (full image shown)
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Start the animation automatically
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when no longer needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          width: 200,  // Set your desired width
          height: 300, // Set your desired height
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _animation.value, // This controls the height of the clipped area
                  child: Image.asset('assets/background_image.jpg'), // Replace with your image asset
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
