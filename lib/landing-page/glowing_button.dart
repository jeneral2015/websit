import 'package:flutter/material.dart';
import 'booking_form.dart';

class GlowingButton extends StatefulWidget {
  final String? argument;
  final String text;
  final VoidCallback? onPressed;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const GlowingButton({
    super.key,
    this.argument,
    required this.text,
    this.onPressed,
    this.fontSize,
    this.padding,
  });

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _opacityAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _elevationAnimation = Tween<double>(
      begin: 4,
      end: 12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: ElevatedButton(
            onPressed:
                widget.onPressed ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookingForm(),
                      settings: RouteSettings(arguments: widget.argument),
                    ),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding:
                  widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _elevationAnimation.value,
              shadowColor: Colors.pink.withValues(alpha: 0.5),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize ?? 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
