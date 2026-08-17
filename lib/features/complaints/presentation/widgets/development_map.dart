import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_nagpur/domain/domain.dart';

/// Configuration-free development map used until an approved map provider and
/// API key are supplied. The marker is adjustable and emits real coordinates;
/// replacing this widget does not affect complaint domain data.
class DevelopmentMap extends StatelessWidget {
  const DevelopmentMap({
    required this.location,
    required this.onChanged,
    super.key,
  });

  final ProblemLocation location;
  final ValueChanged<ProblemLocation> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Development map. Tap to adjust the complaint location pin.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1.45,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final x = (details.localPosition.dx / constraints.maxWidth)
                      .clamp(0.0, 1.0);
                  final y = (details.localPosition.dy / constraints.maxHeight)
                      .clamp(0.0, 1.0);
                  const centerLat = 21.1458;
                  const centerLng = 79.0882;
                  onChanged(
                    location.copyWith(
                      latitude: centerLat + (0.5 - y) * 0.055,
                      longitude: centerLng + (x - 0.5) * 0.07,
                      accuracy: math.max(location.accuracy, 15),
                      address: 'Adjusted pin, Nagpur (development map)',
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _DevelopmentMapPainter(
                        background: scheme.primaryContainer.withValues(
                          alpha: 0.48,
                        ),
                        road: scheme.surface,
                        minorRoad: scheme.surface.withValues(alpha: 0.72),
                        park: const Color(0xFFCFE8D3),
                        water: const Color(0xFFC9E7F2),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'DEVELOPMENT MAP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: scheme.error,
                            size: 48,
                            shadows: const [
                              Shadow(blurRadius: 8, color: Colors.black26),
                            ],
                          ),
                          Transform.translate(
                            offset: const Offset(0, -8),
                            child: Container(
                              width: 10,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app, color: scheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap anywhere to adjust the pin',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DevelopmentMapPainter extends CustomPainter {
  const _DevelopmentMapPainter({
    required this.background,
    required this.road,
    required this.minorRoad,
    required this.park,
    required this.water,
  });

  final Color background;
  final Color road;
  final Color minorRoad;
  final Color park;
  final Color water;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.68,
        -20,
        size.width * 0.38,
        size.height * 0.52,
      ),
      Paint()..color = water,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.12,
          size.width * 0.28,
          size.height * 0.28,
        ),
        const Radius.circular(28),
      ),
      Paint()..color = park,
    );

    final major = Paint()
      ..color = road
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = minorRoad
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-20, size.height * 0.72),
      Offset(size.width + 20, size.height * 0.28),
      major,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, -20),
      Offset(size.width * 0.38, size.height + 20),
      major,
    );
    canvas.drawLine(
      Offset(-10, size.height * 0.28),
      Offset(size.width * 0.72, size.height * 0.56),
      minor,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height + 10),
      Offset(size.width * 0.92, -10),
      minor,
    );
  }

  @override
  bool shouldRepaint(covariant _DevelopmentMapPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.road != road ||
        oldDelegate.minorRoad != minorRoad ||
        oldDelegate.park != park ||
        oldDelegate.water != water;
  }
}
