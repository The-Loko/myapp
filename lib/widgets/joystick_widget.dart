import 'package:flutter/material.dart';
import 'package:control_pad/control_pad.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/car_control_provider.dart';
import '../utils/constants.dart';

class JoystickWidget extends StatelessWidget {
  const JoystickWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CarControlProvider>(context);
    final isActive = provider.isControlActive;
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondaryColor.withAlpha((0.2 * 255).round()),
        border: Border.all(
          color: isActive ? AppColors.accentColor : Colors.grey,
          width: 3,
        ),
      ),
      child: isActive          ? JoystickView(
              onDirectionChanged: (double degrees, double distance) {
                // Convert polar coordinates to cartesian
                final radians = degrees * (math.pi / 180);
                final normalizedDistance = distance.clamp(0.0, 1.0);
                
                final x = normalizedDistance * -1 * math.cos(radians);
                final y = normalizedDistance * math.sin(radians);
                
                provider.updateJoystickPosition(x, y);
              },
              backgroundColor: Colors.transparent,
              innerCircleColor: AppColors.accentColor,
              size: 180,
            )
          : Center(
              child: Icon(
                Icons.gamepad,
                size: 60,
                color: Colors.grey[600],
              ),
            ),
    );
  }
}
