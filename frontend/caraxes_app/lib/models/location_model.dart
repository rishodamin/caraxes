class LocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromMap(String id, Map<String, dynamic> data) {
    return LocationModel(
      id: id,
      name: data['Name'] ?? 'Unknown',
      latitude: double.tryParse(data['Latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(data['Longitude']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}
