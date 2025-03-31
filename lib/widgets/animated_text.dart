import 'package:flutter/material.dart';

class AnimatedLoopText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const AnimatedLoopText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);

  @override
  State<AnimatedLoopText> createState() => _AnimatedLoopTextState();
}

class _AnimatedLoopTextState extends State<AnimatedLoopText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: const Offset(0, -0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Text(
              widget.text,
              style: widget.style,
            ),
          ),
        );
      },
    );
  }
}
