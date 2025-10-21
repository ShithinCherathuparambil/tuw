import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tuw_services/API/endpoint.dart';
import 'package:tuw_services/providers/data_provider.dart';

import 'package:http/http.dart' as http;

/// Request location permission from splash screen using only location package
/// This function uses native GPS enabling and permission requests for the best user experience
/// Uses location package 8.0.1 for native Android dialogs and maximum compatibility
Future<bool> requestLocationPermissionFromSplash() async {
  try {
    print(
        "🚀 Requesting location permission from splash screen with location package...");

    // Initialize location package
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Step 1: Check if location service is enabled
    try {
      serviceEnabled = await location.serviceEnabled();
      print("📡 Location services enabled: $serviceEnabled");
    } catch (e) {
      print("❌ Error checking location services: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 2: If service not enabled, request to enable it natively
    if (!serviceEnabled) {
      print(
          "⚠️ Location services are disabled, requesting to enable natively...");
      try {
        serviceEnabled = await location.requestService();
        print("📱 Native GPS enable request result: $serviceEnabled");
      } catch (e) {
        print("❌ Error requesting location service: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }

      if (!serviceEnabled) {
        print("❌ User declined to enable location services");
        return false;
      }
    }

    // Step 3: Check permission status
    try {
      permissionGranted = await location.hasPermission();
      print("🔐 Current permission status: $permissionGranted");
    } catch (e) {
      print("❌ Error checking permission: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 4: If permission denied, request it natively
    if (permissionGranted == loc.PermissionStatus.denied) {
      print("⚠️ Location permission denied, requesting natively...");
      try {
        permissionGranted = await location.requestPermission();
        print("📱 Native permission request result: $permissionGranted");
      } catch (e) {
        print("❌ Error requesting permission: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }
    }

    // Step 5: Check final permission status
    bool finalPermissionGranted =
        (permissionGranted == loc.PermissionStatus.granted ||
            permissionGranted == loc.PermissionStatus.grantedLimited);

    if (finalPermissionGranted) {
      print("✅ Location permission granted successfully!");

      // Test getting current position to verify everything works
      try {
        loc.LocationData locationData = await location.getLocation();
        print(
            "📍 Test position: ${locationData.latitude}, ${locationData.longitude}");
      } catch (e) {
        print("⚠️ Could not get test position: $e");
        // Still return true as permission was granted
      }
    } else {
      print("❌ Location permission denied: $permissionGranted");
    }

    return finalPermissionGranted;
  } catch (e) {
    print("❌ Unexpected error in splash location permission: $e");
    return false;
  }
}

/// Enhanced location permission and service check using location package for native dialogs
/// This function handles both permission requests and location service enablement
/// Returns true if both permission granted and location services enabled, false otherwise
Future<bool> requestEarlyLocationPermission() async {
  try {
    print("🚀 Requesting early location permission with native dialogs...");

    // Initialize location package for native GPS and permission handling
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Step 1: Check if location service is enabled using location package
    try {
      serviceEnabled = await location.serviceEnabled();
      print("📡 Location services enabled (location pkg): $serviceEnabled");
    } catch (e) {
      print("❌ Error checking location services with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 2: If service not enabled, request to enable it natively
    if (!serviceEnabled) {
      print(
          "⚠️ Location services are disabled, requesting to enable natively...");
      try {
        serviceEnabled = await location.requestService();
        print("📱 Location service request result: $serviceEnabled");
      } catch (e) {
        print("❌ Error requesting location service: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }

      if (!serviceEnabled) {
        print("❌ User declined to enable location services");
        return false;
      }
    }

    // Step 3: Check permission status using location package
    try {
      permissionGranted = await location.hasPermission();
      print("🔐 Current permission status (location pkg): $permissionGranted");
    } catch (e) {
      print("❌ Error checking permission with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 4: If permission denied, request it natively
    if (permissionGranted == loc.PermissionStatus.denied) {
      print("⚠️ Location permission denied, requesting natively...");
      try {
        permissionGranted = await location.requestPermission();
        print(
            "📱 Permission request result (location pkg): $permissionGranted");
      } catch (e) {
        print("❌ Error requesting permission with location package: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }
    }

    // Step 5: Check final permission status
    bool finalPermissionGranted =
        (permissionGranted == loc.PermissionStatus.granted ||
            permissionGranted == loc.PermissionStatus.grantedLimited);

    if (finalPermissionGranted) {
      print("✅ Location permission granted successfully!");

      // Test getting current position to verify everything works
      try {
        loc.LocationData locationData = await location.getLocation();
        print(
            "📍 Test position: ${locationData.latitude}, ${locationData.longitude}");
      } catch (e) {
        print("⚠️ Could not get test position: $e");
        // Still return true as permission was granted
      }
    } else {
      print("❌ Location permission denied: $permissionGranted");
    }

    return finalPermissionGranted;
  } catch (e) {
    print("❌ Unexpected error in early location permission: $e");
    return false;
  }
}

/// Request location permission with native dialogs and integration with viewProfile
/// This function uses the location package for native GPS enabling and permission requests
/// and handles all edge cases for release mode compatibility
Future<bool> _requestLocationPermissionCore() async {
  try {
    print("🚀 Requesting location permission with native dialogs...");

    // Initialize location package for native GPS and permission handling
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Step 1: Check if location service is enabled using location package
    try {
      serviceEnabled = await location.serviceEnabled();
      print("📡 Location services enabled (location pkg): $serviceEnabled");
    } catch (e) {
      print("❌ Error checking location services with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 2: If service not enabled, request to enable it natively
    if (!serviceEnabled) {
      print(
          "⚠️ Location services are disabled, requesting to enable natively...");
      try {
        serviceEnabled = await location.requestService();
        print("📱 Location service request result: $serviceEnabled");
      } catch (e) {
        print("❌ Error requesting location service: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }

      if (!serviceEnabled) {
        print("❌ User declined to enable location services");
        return false;
      }
    }

    // Step 3: Check permission status using location package
    try {
      permissionGranted = await location.hasPermission();
      print("🔐 Current permission status (location pkg): $permissionGranted");
    } catch (e) {
      print("❌ Error checking permission with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 4: If permission denied, request it natively
    if (permissionGranted == loc.PermissionStatus.denied) {
      print("⚠️ Location permission denied, requesting natively...");
      try {
        permissionGranted = await location.requestPermission();
        print(
            "📱 Permission request result (location pkg): $permissionGranted");
      } catch (e) {
        print("❌ Error requesting permission with location package: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }
    }

    // Step 5: Check final permission status
    bool finalPermissionGranted =
        (permissionGranted == loc.PermissionStatus.granted ||
            permissionGranted == loc.PermissionStatus.grantedLimited);

    return finalPermissionGranted;
  } catch (e) {
    print("❌ Unexpected error in location permission: $e");
    return false;
  }
}

/// Request location permission for explorer feature with native dialogs
/// This function uses the location package for native GPS enabling and permission requests
/// and handles all edge cases for release mode compatibility
Future<bool> _requestExplorerLocationPermissionCore() async {
  try {
    print("🚀 Requesting explorer location permission with native dialogs...");

    // Initialize location package for native GPS and permission handling
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Step 1: Check if location service is enabled using location package
    try {
      serviceEnabled = await location.serviceEnabled();
      print("📡 Location services enabled (location pkg): $serviceEnabled");
    } catch (e) {
      print("❌ Error checking location services with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 2: If service not enabled, request to enable it natively
    if (!serviceEnabled) {
      print(
          "⚠️ Location services are disabled, requesting to enable natively...");
      try {
        serviceEnabled = await location.requestService();
        print("📱 Location service request result: $serviceEnabled");
      } catch (e) {
        print("❌ Error requesting location service: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }

      if (!serviceEnabled) {
        print("❌ User declined to enable location services");
        return false;
      }
    }

    // Step 3: Check permission status using location package
    try {
      permissionGranted = await location.hasPermission();
      print("🔐 Current permission status (location pkg): $permissionGranted");
    } catch (e) {
      print("❌ Error checking permission with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // Step 4: If permission denied, request it natively
    if (permissionGranted == loc.PermissionStatus.denied) {
      print("⚠️ Location permission denied, requesting natively...");
      try {
        permissionGranted = await location.requestPermission();
        print(
            "📱 Permission request result (location pkg): $permissionGranted");
      } catch (e) {
        print("❌ Error requesting permission with location package: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }
    }

    // Step 5: Check final permission status
    bool finalPermissionGranted =
        (permissionGranted == loc.PermissionStatus.granted ||
            permissionGranted == loc.PermissionStatus.grantedLimited);

    return finalPermissionGranted;
  } catch (e) {
    print("❌ Unexpected error in explorer location permission: $e");
    return false;
  }
}

/// Send current location using location package
/// Returns LocationData if successful, null if location services fail
Future<loc.LocationData?> _sendCurrentLocationCore() async {
  try {
    print("📍 Getting current location for sending...");

    loc.Location location = loc.Location();
    loc.LocationData locationData = await location.getLocation();

    print(
        "✅ Current location obtained: ${locationData.latitude}, ${locationData.longitude}");
    return locationData;
  } catch (e) {
    print("❌ Error getting current location: $e");
    return null;
  }
}

/// Get current location permission status and coordinates with native dialogs
/// This function uses the location package for native GPS enabling and permission requests
/// Returns LocationData with coordinates or fallback coordinates if location fails
Future<loc.LocationData> _getCurrentLocationPermissionCore() async {
  try {
    print("🚀 Getting current location permission with native dialogs...");

    // Initialize location package for native GPS and permission handling
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Step 1: Check if location service is enabled using location package
    try {
      serviceEnabled = await location.serviceEnabled();
      print("📡 Location services enabled (location pkg): $serviceEnabled");
    } catch (e) {
      print("❌ Error checking location services with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return _getFallbackLocationData();
      }
      return _getFallbackLocationData();
    }

    // Step 2: If service not enabled, request to enable it natively
    if (!serviceEnabled) {
      print(
          "⚠️ Location services are disabled, requesting to enable natively...");
      try {
        serviceEnabled = await location.requestService();
        print("📱 Location service request result: $serviceEnabled");
      } catch (e) {
        print("❌ Error requesting location service: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return _getFallbackLocationData();
        }
        return _getFallbackLocationData();
      }

      if (!serviceEnabled) {
        print("❌ User declined to enable location services");
        return _getFallbackLocationData();
      }
    }

    // Step 3: Check permission status using location package
    try {
      permissionGranted = await location.hasPermission();
      print("🔐 Current permission status (location pkg): $permissionGranted");
    } catch (e) {
      print("❌ Error checking permission with location package: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return _getFallbackLocationData();
      }
      return _getFallbackLocationData();
    }

    // Step 4: If permission denied, request it natively
    if (permissionGranted == loc.PermissionStatus.denied) {
      print("⚠️ Location permission denied, requesting natively...");
      try {
        permissionGranted = await location.requestPermission();
        print(
            "📱 Permission request result (location pkg): $permissionGranted");
      } catch (e) {
        print("❌ Error requesting permission with location package: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return _getFallbackLocationData();
        }
        return _getFallbackLocationData();
      }
    }

    // Step 5: Check final permission status and get location
    bool finalPermissionGranted =
        (permissionGranted == loc.PermissionStatus.granted ||
            permissionGranted == loc.PermissionStatus.grantedLimited);

    if (finalPermissionGranted) {
      print("✅ Location permission granted, getting current position...");
      try {
        loc.LocationData locationData = await location.getLocation();
        print(
            "📍 Position obtained: ${locationData.latitude}, ${locationData.longitude}");
        return locationData;
      } catch (e) {
        print("❌ Error getting current position: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return _getFallbackLocationData();
        }
        return _getFallbackLocationData();
      }
    } else {
      print("❌ Location permissions are denied by user: $permissionGranted");
      return _getFallbackLocationData();
    }
  } catch (e) {
    print("❌ Unexpected error in getCurrentLocationPermission: $e");
    return _getFallbackLocationData();
  }
}

/// Returns fallback coordinates for Muscat, Oman when location services fail
loc.LocationData _getFallbackLocationData() {
  print("🏠 Using fallback coordinates: Muscat, Oman (23.5859, 58.4059)");
  return loc.LocationData.fromMap({
    'latitude': 23.5859,
    'longitude': 58.4059,
    'accuracy': 0.0,
    'altitude': 0.0,
    'heading': 0.0,
    'speed': 0.0,
    'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
  });
}

// Backward compatibility functions that accept context parameter but ignore it

/// Backward compatibility wrapper for requestLocationPermission that accepts context
Future<bool> requestLocationPermission(BuildContext context) async {
  return await _requestLocationPermissionCore();
}

/// Backward compatibility wrapper for requestExplorerLocationPermission that accepts context
Future<bool> requestExplorerLocationPermission(BuildContext context) async {
  return await _requestExplorerLocationPermissionCore();
}

/// Backward compatibility wrapper for sendCurrentLocation that accepts context
Future<loc.LocationData?> sendCurrentLocation(BuildContext context) async {
  return await _sendCurrentLocationCore();
}

/// Backward compatibility wrapper for getCurrentLocationPermission that accepts context
Future<loc.LocationData> getCurrentLocationPermission(
    BuildContext context) async {
  return await _getCurrentLocationPermissionCore();
}

/// Get current location using location package
/// Returns LocationData with coordinates or fallback coordinates if location fails
Future<loc.LocationData> getCurrentLocation() async {
  try {
    print("📍 Getting current location...");

    loc.Location location = loc.Location();
    loc.LocationData locationData = await location.getLocation();

    print(
        "✅ Current location obtained: ${locationData.latitude}, ${locationData.longitude}");
    return locationData;
  } catch (e) {
    print("❌ Error getting current location: $e");
    return _getFallbackLocationData();
  }
}

/// Show location service dialog using native GPS enable request
/// This function uses the location package for native GPS enabling
/// Returns true if user enables GPS, false otherwise
Future<bool> showLocationServiceDialog(BuildContext context) async {
  try {
    print("🚀 Showing native GPS enable dialog...");

    // Initialize location package for native GPS enabling
    loc.Location location = loc.Location();
    bool serviceEnabled;

    // Check if location service is enabled
    try {
      serviceEnabled = await location.serviceEnabled();
      print("📡 Location services enabled: $serviceEnabled");
    } catch (e) {
      print("❌ Error checking location services: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("🚫 Location plugin not available in release mode");
        return false;
      }
      return false;
    }

    // If service not enabled, request to enable it natively
    if (!serviceEnabled) {
      print(
          "⚠️ Location services are disabled, requesting to enable natively...");
      try {
        serviceEnabled = await location.requestService();
        print("📱 Native GPS enable request result: $serviceEnabled");
        return serviceEnabled;
      } catch (e) {
        print("❌ Error requesting location service: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return false;
        }
        return false;
      }
    }

    // Service already enabled
    print("✅ Location services already enabled");
    return true;
  } catch (e) {
    print("❌ Unexpected error in showLocationServiceDialog: $e");
    return false;
  }
}

/// Send location coordinates to the server
/// This function sends the provided coordinates to update the user's location
Future<void> sendLocation(BuildContext context, String coordinates) async {
  try {
    print("📤 Sending location: $coordinates");

    // Parse coordinates (format: "lat,lon")
    List<String> coords = coordinates.split(',');
    if (coords.length != 2) {
      print("❌ Invalid coordinates format: $coordinates");
      return;
    }

    double latitude = double.parse(coords[0]);
    double longitude = double.parse(coords[1]);

    // Get address from coordinates
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      String locality = '';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        locality =
            '${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
      }

      // Call the update location API
      final provider = Provider.of<DataProvider>(context, listen: false);
      String? apiToken = Hive.box("token").get('api_token');

      if (apiToken == null) {
        print("❌ No API token found");
        return;
      }

      var response = await http.post(
          Uri.parse(
              '$updateLocationApi$locality&latitude=$latitude&longitude=$longitude'),
          headers: {
            "device-id": provider.deviceId ?? '',
            "api-token": apiToken
          });

      if (response.statusCode == 200) {
        print("✅ Location sent successfully");
      } else {
        print("❌ Failed to send location: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error getting address or sending location: $e");
    }
  } catch (e) {
    print("❌ Error parsing coordinates: $e");
  }
}
