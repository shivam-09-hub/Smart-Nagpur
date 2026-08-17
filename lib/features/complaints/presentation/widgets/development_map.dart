import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:url_launcher/url_launcher.dart';

/// Real interactive map widget supporting Street and Satellite views,
/// interactive pin adjustment, zoom controls, and Google Maps launching.
class DevelopmentMap extends StatefulWidget {
  const DevelopmentMap({
    required this.location,
    this.onChanged,
    this.isEditable = true,
    this.showControls = true,
    this.aspectRatio = 1.45,
    super.key,
  });

  final ProblemLocation location;
  final ValueChanged<ProblemLocation>? onChanged;
  final bool isEditable;
  final bool showControls;
  final double aspectRatio;

  @override
  State<DevelopmentMap> createState() => _DevelopmentMapState();
}

class _DevelopmentMapState extends State<DevelopmentMap> {
  late final MapController _mapController;
  bool _isSatellite = false;
  double _currentZoom = 15.5;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant DevelopmentMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.latitude != widget.location.latitude ||
        oldWidget.location.longitude != widget.location.longitude) {
      _mapController.move(
        LatLng(widget.location.latitude, widget.location.longitude),
        _currentZoom,
      );
    }
  }

  Future<void> _openInGoogleMaps() async {
    final lat = widget.location.latitude;
    final lng = widget.location.longitude;
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1.0).clamp(4.0, 19.0);
    _mapController.move(
      LatLng(widget.location.latitude, widget.location.longitude),
      _currentZoom,
    );
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1.0).clamp(4.0, 19.0);
    _mapController.move(
      LatLng(widget.location.latitude, widget.location.longitude),
      _currentZoom,
    );
  }

  void _recenter() {
    _mapController.move(
      LatLng(widget.location.latitude, widget.location.longitude),
      16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final center = LatLng(widget.location.latitude, widget.location.longitude);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Map Canvas
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _currentZoom,
                minZoom: 3.0,
                maxZoom: 19.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: widget.isEditable && widget.onChanged != null
                    ? (tapPosition, point) {
                        widget.onChanged!(
                          widget.location.copyWith(
                            latitude: point.latitude,
                            longitude: point.longitude,
                            address:
                                'Selected pin (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})',
                          ),
                        );
                      }
                    : null,
                onPositionChanged: (camera, hasGesture) {
                  _currentZoom = camera.zoom;
                },
              ),
              children: [
                // Tile Layer (Street vs Satellite)
                TileLayer(
                  urlTemplate: _isSatellite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartnagpur.citizen',
                  maxZoom: 19,
                ),

                // Accuracy circle around pin
                if (widget.location.accuracy > 0)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: center,
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderColor: scheme.primary.withValues(alpha: 0.6),
                        borderStrokeWidth: 1.5,
                        useRadiusInMeter: true,
                        radius: widget.location.accuracy.clamp(10.0, 300.0),
                      ),
                    ],
                  ),

                // Pin Marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Colors.red.shade600,
                            size: 42,
                            shadows: const [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black54,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          Container(
                            width: 8,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top-left: Map Type & Mode Badge
            Positioned(
              left: 12,
              top: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isSatellite = !_isSatellite;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSatellite ? Icons.satellite_alt : Icons.map_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isSatellite ? 'SATELLITE' : 'STREET MAP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top-right: Open in Google Maps Button
            Positioned(
              right: 12,
              top: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openInGoogleMaps,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          color: scheme.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Google Maps',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom-right: Zoom and Recenter Controls
            if (widget.showControls)
              Positioned(
                right: 12,
                bottom: widget.isEditable ? 48 : 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconButton(
                      icon: Icons.add,
                      onTap: _zoomIn,
                      tooltip: 'Zoom in',
                    ),
                    const SizedBox(height: 4),
                    _buildIconButton(
                      icon: Icons.remove,
                      onTap: _zoomOut,
                      tooltip: 'Zoom out',
                    ),
                    const SizedBox(height: 4),
                    _buildIconButton(
                      icon: Icons.my_location,
                      onTap: _recenter,
                      tooltip: 'Recenter on pin',
                      iconColor: scheme.primary,
                    ),
                  ],
                ),
              ),

            // Bottom-left: Tap to adjust prompt (when editable)
            if (widget.isEditable && widget.onChanged != null)
              Positioned(
                left: 12,
                right: 56,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: scheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tap map to reposition pin',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Alias for compatibility
typedef InteractiveCityMap = DevelopmentMap;
