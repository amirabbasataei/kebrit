/// Floating joystick drawn at the first touch point (MGame): an 80 px ring and
/// a 36 px knob. Coordinates are in the 390×844 design space.
library;

import 'package:flutter/widgets.dart';

import '../../kit/css.dart';

/// Drag state: [ox],[oy] = first touch point, [kx],[ky] = clamped knob offset.
class JoystickDrag {
  const JoystickDrag(this.ox, this.oy, [this.kx = 0, this.ky = 0]);

  final double ox, oy, kx, ky;

  @override
  bool operator ==(Object other) =>
      other is JoystickDrag &&
      other.ox == ox &&
      other.oy == oy &&
      other.kx == kx &&
      other.ky == ky;

  @override
  int get hashCode => Object.hash(ox, oy, kx, ky);
}

class JoystickOverlay extends StatelessWidget {
  const JoystickOverlay({super.key, required this.drag});

  final JoystickDrag drag;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: drag.ox - 40,
        top: drag.oy - 40,
        width: 80,
        height: 80,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rgba(255, 210, 150, .06),
              border: Border.all(color: rgba(255, 210, 150, .35), width: 2),
            ),
          ),
        ),
      ),
      Positioned(
        left: drag.ox + drag.kx - 18,
        top: drag.oy + drag.ky - 18,
        width: 36,
        height: 36,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rgba(255, 210, 150, .35),
              boxShadow: cssBoxShadows([
                CssShadow(0, 0, 16, 0, rgba(255, 170, 80, .4)),
              ]),
            ),
          ),
        ),
      ),
    ],
  );
}
