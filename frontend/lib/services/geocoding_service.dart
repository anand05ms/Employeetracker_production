// lib/services/geocoding_service.dart
// NEW SERVICE: Convert GPS coordinates to human-readable addresses

import 'package:geocoding/geocoding.dart';

class GeocodingService {
  // Cache to avoid repeated API calls for same location
  static final Map<String, String> _addressCache = {};

  /// Convert latitude and longitude to a readable address
  /// Returns: "123 Main St, Chennai, Tamil Nadu"
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Create cache key
      final cacheKey =
          '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

      // Check cache first
      if (_addressCache.containsKey(cacheKey)) {
        print('📍 Address from cache: ${_addressCache[cacheKey]}');
        return _addressCache[cacheKey]!;
      }

      print('🌍 Fetching address for: $latitude, $longitude');

      // Fetch from geocoding API
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isEmpty) {
        return 'Location unavailable';
      }

      Placemark place = placemarks[0];

      // Build readable address
      String address = _buildAddress(place);

      // Cache it
      _addressCache[cacheKey] = address;

      print('✅ Address resolved: $address');
      return address;
    } catch (e) {
      print('❌ Geocoding error: $e');
      return 'Location: $latitude, $longitude';
    }
  }

  /// Build a clean, readable address from placemark
  String _buildAddress(Placemark place) {
    List<String> parts = [];

    // Add street/sublocality
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    // Add locality (city/town)
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    // Add administrative area (state)
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    // Add country if different from India (assuming most users in India)
    if (place.country != null && place.country != 'India') {
      parts.add(place.country!);
    }

    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }

  /// Get short address (just locality and area)
  /// Returns: "Chennai, Tamil Nadu"
  Future<String> getShortAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isEmpty) return 'Unknown';

      Placemark place = placemarks[0];

      List<String> parts = [];

      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add(place.locality!);
      }

      if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty) {
        parts.add(place.administrativeArea!);
      }

      return parts.isEmpty ? 'Unknown' : parts.join(', ');
    } catch (e) {
      print('❌ Short address error: $e');
      return 'Unknown';
    }
  }

  /// Get just the city name
  /// Returns: "Chennai"
  Future<String> getCityName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isEmpty) return 'Unknown';

      return placemarks[0].locality ?? 'Unknown';
    } catch (e) {
      print('❌ City name error: $e');
      return 'Unknown';
    }
  }

  /// Clear the address cache (call when memory is low)
  void clearCache() {
    _addressCache.clear();
    print('🗑️ Address cache cleared');
  }

  /// Get cache size
  int get cacheSize => _addressCache.length;
}
