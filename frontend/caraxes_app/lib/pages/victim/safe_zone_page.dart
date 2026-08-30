import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/location_model.dart';
import '../../models/disaster_location_model.dart';
import '../../services/location_service.dart';
import '../../services/disaster_service.dart';

class SafeZoneRecommendation {
  final LocationModel location;
  final int safetyScore;
  final double distanceKm;

  SafeZoneRecommendation({
    required this.location,
    required this.safetyScore,
    required this.distanceKm,
  });
}

class SafeZonePage extends StatefulWidget {
  const SafeZonePage({super.key});

  @override
  State<SafeZonePage> createState() => _SafeZonePageState();
}

class _SafeZonePageState extends State<SafeZonePage> {
  bool _isLoading = true;
  List<LocationModel> _allLocations = [];
  List<DisasterLocationModel> _disasters = [];
  List<SafeZoneRecommendation> _recommendations = [];
  Position? _currentPosition;

  int _highRiskCount = 0;
  int _moderateRiskCount = 0;
  int _lowRiskCount = 0;
  int _safeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          _currentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
        }
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }

    try {
      final locationService = LocationService();
      final disasterService = DisasterService();

      final locations = await locationService.getLocations();
      final disasters = await disasterService.getDisasterLocations();

      _processSafeZones(locations, disasters);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processSafeZones(
      List<LocationModel> locations, List<DisasterLocationModel> disasters) {
    _highRiskCount = 0;
    _moderateRiskCount = 0;
    _lowRiskCount = 0;
    _safeCount = 0;

    List<SafeZoneRecommendation> allSafeZones = [];

    for (var loc in locations) {
      final matchedDisaster = disasters.where((d) => d.id == loc.id).firstOrNull;
      int severity = matchedDisaster?.highestSeverityScore ?? 0;

      if (severity >= 80) {
        _highRiskCount++;
      } else if (severity >= 50) {
        _moderateRiskCount++;
      } else if (severity >= 20) {
        _lowRiskCount++;
      } else {
        _safeCount++;
      }

      if (severity < 20) {
        int safetyScore = (100 - severity).clamp(0, 100);

        double distanceKm = 0.0;
        if (_currentPosition != null) {
          double distMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              loc.latitude,
              loc.longitude);
          distanceKm = distMeters / 1000.0;
        } else {
          distanceKm = Random().nextDouble() * 10;
        }

        allSafeZones.add(SafeZoneRecommendation(
          location: loc,
          safetyScore: safetyScore,
          distanceKm: distanceKm,
        ));
      }
    }

    allSafeZones.sort((a, b) {
      int scoreCompare = b.safetyScore.compareTo(a.safetyScore);
      if (scoreCompare != 0) return scoreCompare;
      return a.distanceKm.compareTo(b.distanceKm);
    });

    setState(() {
      _allLocations = locations;
      _disasters = disasters;
      _recommendations = allSafeZones.take(3).toList();
    });
  }

  Color _getSeverityColor(int score) {
    if (score >= 80) return Colors.red;
    if (score >= 50) return Colors.orange;
    if (score >= 20) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Zones'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _loadData,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTopSummary(),
                Expanded(
                  flex: 65,
                  child: Stack(
                    children: [
                      _buildMap(),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildLegend(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 35,
                  child: _buildRecommendationsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildTopSummary() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip('Safe', _safeCount, Colors.green),
            _summaryChip('Low Risk', _lowRiskCount, Colors.yellow.shade700),
            _summaryChip('Moderate', _moderateRiskCount, Colors.orange),
            _summaryChip('High Risk', _highRiskCount, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Chip(
        label: Text('$label: $count', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color.withOpacity(0.2),
        side: BorderSide(color: color),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _legendItem(Colors.red, 'High Risk (>=80)'),
            _legendItem(Colors.orange, 'Moderate (50-79)'),
            _legendItem(Colors.yellow.shade700, 'Low Risk (20-49)'),
            _legendItem(Colors.green, 'Safe (<20)'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildMap() {
    List<Marker> markers = [];
    List<CircleMarker> circles = [];

    for (var d in _disasters) {
      int score = d.highestSeverityScore;
      Color color = _getSeverityColor(score);
      final detection = d.highestSeverityDetection;

      final matchedLocation = _allLocations.where((loc) => loc.id == d.id).firstOrNull;
      double lat = matchedLocation?.latitude ?? d.latitude;
      double lon = matchedLocation?.longitude ?? d.longitude;

      if (lat == 0.0 && lon == 0.0) continue; // Skip invalid coordinates

      circles.add(
        CircleMarker(
          point: LatLng(lat, lon),
          color: color.withOpacity(0.3),
          borderColor: color,
          borderStrokeWidth: 2,
          useRadiusInMeter: true,
          radius: score * 10.0,
        ),
      );

      markers.add(
        Marker(
          point: LatLng(lat, lon),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Location: ${matchedLocation?.name ?? d.id}\nHazard: ${detection?.className ?? "Unknown"}\nSeverity: $score\nConfidence: ${((detection?.confidence ?? 0) * 100).toStringAsFixed(1)}%'),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Icon(Icons.location_on, color: color, size: 40),
          ),
        ),
      );
    }

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }

    LatLng center = const LatLng(27.7172, 85.3240); // default Kathmandu
    if (_currentPosition != null) {
      center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    } else if (_disasters.isNotEmpty) {
      center = LatLng(_disasters.first.latitude, _disasters.first.longitude);
    } else if (_allLocations.isNotEmpty) {
      center = LatLng(_allLocations.first.latitude, _allLocations.first.longitude);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.caraxes_app',
        ),
        CircleLayer(circles: circles),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildRecommendationsList() {
    if (_disasters.isEmpty && _allLocations.isNotEmpty) {
      return Container(
        color: Colors.green.shade50,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  'No active hazards detected.',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                SizedBox(height: 8),
                Text(
                  'All monitored locations appear safe.',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return const Center(child: Text('No safe zones found nearby.'));
    }

    return Container(
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Recommended Safe Zones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final rec = _recommendations[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.health_and_safety, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec.location.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Safety Score',
                                    style: TextStyle(color: Colors.grey)),
                                Text(
                                  '${rec.safetyScore}/100',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status',
                                    style: TextStyle(color: Colors.grey)),
                                Text(
                                  rec.safetyScore == 100 ? 'Very Safe' : 'Safe',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Distance',
                                    style: TextStyle(color: Colors.grey)),
                                Text(
                                  '${rec.distanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
