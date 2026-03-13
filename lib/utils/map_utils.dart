/// Utilities for maps, navigation addresses, and polyline decoding.
class MapUtils {
  MapUtils._();

  /// Decodes Google's encoded polyline string into a list of (lat, lng) pairs.
  static List<({double lat, double lng})> decodePolyline(String encoded) {
    final points = <({double lat, double lng})>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add((
        lat: lat / 1e5,
        lng: lng / 1e5,
      ));
    }
    return points;
  }

  /// Returns the primary destination address for an errand (for navigation).
  /// Used so the runner can open maps to the correct location.
  static String? getErrandNavigationAddress(Map<String, dynamic> errand) {
    final category = errand['category']?.toString().toLowerCase() ?? '';

    switch (category) {
      case 'shopping':
        final delivery = errand['delivery_address']?.toString().trim();
        if (delivery != null && delivery.isNotEmpty) return delivery;
        return errand['location_address']?.toString().trim();

      case 'delivery':
        final delivery = errand['delivery_address']?.toString().trim();
        if (delivery != null && delivery.isNotEmpty) return delivery;
        final pickup = errand['pickup_address'] ?? errand['location_address'];
        return pickup?.toString().trim();

      case 'document_services':
      case 'license_discs':
        final dropoff =
            (errand['dropoff_location'] ?? errand['dropoff_address'])
                ?.toString()
                .trim();
        if (dropoff != null && dropoff.isNotEmpty) return dropoff;
        final pickup =
            (errand['pickup_location'] ?? errand['pickup_address'])
                ?.toString()
                .trim();
        if (pickup != null && pickup.isNotEmpty) return pickup;
        return errand['location_address']?.toString().trim();

      default:
        final loc = errand['location_address']?.toString().trim();
        if (loc != null && loc.isNotEmpty) return loc;
        final delivery = errand['delivery_address']?.toString().trim();
        if (delivery != null && delivery.isNotEmpty) return delivery;
        return null;
    }
  }
}
