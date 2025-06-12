import 'package:flutter/material.dart';
import 'dart:math';

class JoystickWidget extends StatefulWidget {
  final Function(double x, double y) onChanged;
  final double size;
  final bool enabled;
  
  const JoystickWidget({
    super.key,
    required this.onChanged,
    this.size = 200.0,
    this.enabled = true,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  double _knobX = 0.0;
  double _knobY = 0.0;
  late double _radius;
  late double _knobRadius;

  @override
  void initState() {
    super.initState();
    _radius = widget.size / 2;
    _knobRadius = _radius * 0.3;
  }

  void _updateKnobPosition(Offset localPosition) {
    if (!widget.enabled) return;

    final center = Offset(_radius, _radius);
    final delta = localPosition - center;
    final distance = delta.distance;
    
    if (distance <= _radius - _knobRadius) {
      _knobX = delta.dx;
      _knobY = delta.dy;
    } else {
      // Constrain to circle boundary
      final angle = atan2(delta.dy, delta.dx);
      final maxDistance = _radius - _knobRadius;
      _knobX = cos(angle) * maxDistance;
      _knobY = sin(angle) * maxDistance;
    }
    
    // Convert to normalized values (-1.0 to 1.0)
    final normalizedX = _knobX / (_radius - _knobRadius);
    final normalizedY = -_knobY / (_radius - _knobRadius); // Invert Y for intuitive controls
    
    setState(() {});
    widget.onChanged(normalizedX, normalizedY);
  }

  void _resetKnobPosition() {
    setState(() {
      _knobX = 0.0;
      _knobY = 0.0;
    });
    widget.onChanged(0.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        _updateKnobPosition(details.localPosition);
      },
      onPanEnd: (details) {
        _resetKnobPosition();
      },
      onTapUp: (details) {
        _updateKnobPosition(details.localPosition);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.enabled 
              ? Colors.grey[300] 
              : Colors.grey[200],
          border: Border.all(
            color: widget.enabled 
                ? Colors.grey[600]! 
                : Colors.grey[400]!,
            width: 3,
          ),
          boxShadow: [            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center crosshairs
            Center(
              child: Container(
                width: 4,
                height: widget.size * 0.8,
                color: Colors.grey[400],
              ),
            ),
            Center(
              child: Container(
                width: widget.size * 0.8,
                height: 4,
                color: Colors.grey[400],
              ),
            ),
            
            // Joystick knob
            Positioned(
              left: _radius + _knobX - _knobRadius,
              top: _radius + _knobY - _knobRadius,
              child: Container(
                width: _knobRadius * 2,
                height: _knobRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.enabled 
                      ? const Color(0xFF008080) // AppColors.accentColor
                      : Colors.grey[400],
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: _knobRadius * 0.6,
                    height: _knobRadius * 0.6,                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
