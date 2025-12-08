/// Model class for store locations
class StoreLocation {
  final String locationType; // 'name' or 'map'
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;

  StoreLocation({
    this.locationType = 'name',
    this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  StoreLocation copyWith({
    String? locationType,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return StoreLocation(
      locationType: locationType ?? this.locationType,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationType': locationType,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory StoreLocation.fromMap(Map<String, dynamic> map) {
    return StoreLocation(
      locationType: map['locationType'] ?? 'name',
      name: map['name'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  String get displayName {
    if (locationType == 'name') {
      return name ?? 'Unnamed Store';
    } else {
      return address ?? 'Unknown Location';
    }
  }
}
