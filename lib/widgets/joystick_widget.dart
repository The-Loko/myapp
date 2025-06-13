import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:provider/provider.dart';
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
      child: isActive
          ? Joystick(
              listener: (StickDragDetails details) {
                // The flutter_joystick package provides x,y values in -1 to 1 range
                provider.updateJoystickPosition(details.x, details.y);
              },
              base: JoystickBase(
                decoration: JoystickBaseDecoration(
                  color: Colors.transparent,
                  drawOuterCircle: false,
                ),
              ),
              stick: JoystickStick(
                decoration: JoystickStickDecoration(
                  color: AppColors.accentColor,
                  shadowColor: AppColors.accentColor.withOpacity(0.5),
                ),
              ),
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
