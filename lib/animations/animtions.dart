import 'package:flutter/material.dart';

//function to animate opacity and position on the Y axis
class FadeCustomAnimation extends StatefulWidget {
  final double delay;
  final Widget? child;
  final bool fromBottom;

  const FadeCustomAnimation(
      {super.key, this.delay = 1, this.child, this.fromBottom = false});

  @override
  State<FadeCustomAnimation> createState() => _FadeCustomAnimationState();
}

class _FadeCustomAnimationState extends State<FadeCustomAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _translateAnimation = Tween<double>(
      begin: widget.fromBottom ? 30.0 : -30.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation with delay
    Future.delayed(Duration(milliseconds: (500 * widget.delay).round()), () {
      if (mounted) {
        _controller.forward();
      }
    });
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
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _opacityAnimation.value,
        child: Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: child,
        ),
      ),
    );
  }
}

//function to animate opacity and position on the X axis
class FadeSlideCustomAnimation extends StatefulWidget {
  final double delay;
  final Widget? child;
  final bool isRight;

  const FadeSlideCustomAnimation(
      {super.key, this.delay = 1, this.child, this.isRight = false});

  @override
  State<FadeSlideCustomAnimation> createState() =>
      _FadeSlideCustomAnimationState();
}

class _FadeSlideCustomAnimationState extends State<FadeSlideCustomAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _translateAnimation = Tween<double>(
      begin: widget.isRight ? 30.0 : -30.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation with delay
    Future.delayed(Duration(milliseconds: (500 * widget.delay).round()), () {
      if (mounted) {
        _controller.forward();
      }
    });
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
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _opacityAnimation.value,
        child: Transform.translate(
          offset: Offset(_translateAnimation.value, 0),
          child: child,
        ),
      ),
    );
  }
}
