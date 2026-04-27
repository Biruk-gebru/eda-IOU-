import 'package:flutter/material.dart';

class NeoButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color? backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const NeoButton({
    super.key,
    required this.onTap,
    required this.child,
    this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 1.5,
    this.shadowOffset = 4.0,
    this.padding = const EdgeInsets.symmetric(vertical: 18),
    this.alignment = Alignment.center,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        curve: Curves.easeOutQuad,
        transform: Matrix4.translationValues(
          _isPressed ? widget.shadowOffset : 0,
          _isPressed ? widget.shadowOffset : 0,
          0,
        ),
        padding: widget.padding,
        alignment: widget.alignment,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.transparent,
          border: Border.all(color: widget.borderColor, width: widget.borderWidth),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.borderColor,
                offset: Offset(widget.shadowOffset, widget.shadowOffset),
              ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
