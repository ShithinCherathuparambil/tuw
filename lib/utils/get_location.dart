// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tuw_services/API/endpoint.dart';
import 'package:tuw_services/API/home/get_service_man.dart';
import 'package:tuw_services/API/updateLocation.dart';
import 'package:tuw_services/API/viewProfile.dart';
import 'package:tuw_services/providers/data_provider.dart';
import 'package:tuw_services/utils/animatedSnackBar.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';

// Enhanced location permission and service check
// This function handles both permission requests and location service enablement
// Returns true if both permission granted and location services enabled, false otherwise
Future<bool> requestEarlyLocationPermission() async {
  print("Requesting early location permission...");

  // Step 1: Check current permission status first
  LocationPermission permission = LocationPermission.denied;
  bool pluginAvailable = true;

  try {
    await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();
    print("Current location permission: $permission");
  } catch (e) {
    print("Error checking location permission: $e");
    if (e.toString().contains('MissingPluginException')) {
      print("Permission check failed - plugin not available");
      pluginAvailable = false;
      return false;
    }
    permission = LocationPermission.denied;
  }

  // Step 2: Request permission if not granted
  if (permission == LocationPermission.denied) {
    try {
      print("Requesting location permission...");
      permission = await Geolocator.requestPermission();
      print("Permission request result: $permission");
    } catch (e) {
      print("Error requesting location permission: $e");
      if (e.toString().contains('MissingPluginException')) {
        print("Permission request failed - plugin not available");
        return false;
      }
      permission = LocationPermission.denied;
    }
  }

  // Step 3: Check if permission is granted
  bool permissionGranted = (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always);

  if (!permissionGranted) {
    print("Location permission not granted: $permission");
    return false;
  }

  // Step 4: If permission granted, check if location services are enabled
  bool serviceEnabled = false;
  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Location service enabled: $serviceEnabled");
  } catch (e) {
    print("Error checking location service status: $e");
    if (e.toString().contains('MissingPluginException')) {
      print("Location service check failed - plugin not available");
      return false;
    }
    serviceEnabled = false;
  }

  print(
      "Early location check - Permission: $permissionGranted, Service: $serviceEnabled");
  return permissionGranted && serviceEnabled;
}

requestLocationPermission(
  BuildContext context,
) async {
  final str = AppLocalizations.of(context)!;

  // Step 1: Check current permission status first
  LocationPermission permission = LocationPermission.denied;
  bool pluginAvailable = true;

  try {
    permission = await Geolocator.checkPermission();
    print("Current location permission: $permission");
  } catch (e) {
    print("Error checking location permission: $e");
    if (e.toString().contains('MissingPluginException')) {
      print("Permission check failed - plugin not available, using fallback");
      pluginAvailable = false;
      await viewProfile(context);
      return;
    }
    permission = LocationPermission.denied;
  }

  // Step 2: Request permission if not granted
  if (permission == LocationPermission.denied && pluginAvailable) {
    try {
      print("Requesting location permission...");
      permission = await Geolocator.requestPermission();
      print("Permission request result: $permission");
    } catch (e) {
      print("Error requesting location permission: $e");
      if (e.toString().contains('MissingPluginException')) {
        print(
            "Permission request failed - plugin not available, using fallback");
        await viewProfile(context);
        return;
      }
      permission = LocationPermission.denied;
    }
  }

  // Step 3: Handle permission results
  if (permission == LocationPermission.denied) {
    print('Location permissions are denied');
    showAnimatedSnackBar(context, str.snack_enable_loc);
    await viewProfile(context);
    return;
  } else if (permission == LocationPermission.deniedForever) {
    print("Location permissions are permanently denied");
    showAnimatedSnackBar(context, str.snack_enable_loc);
    await viewProfile(context);
    return;
  }

  // Step 4: Permission granted, now check if location services are enabled
  bool serviceEnabled = false;
  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Location service enabled: $serviceEnabled");
  } catch (e) {
    print("Error checking location service status: $e");
    if (e.toString().contains('MissingPluginException')) {
      print(
          "Location service check failed - plugin not available, using fallback");
      await viewProfile(context);
      return;
    }
    serviceEnabled = false;
  }

  // Step 5: If location services disabled, show dialog to enable
  if (!serviceEnabled && pluginAvailable) {
    print("Location services disabled - showing dialog");
    await showLocationServiceDialog(context);
    return;
  }

  // Step 6: Both permission granted and services enabled - get location
  print("GPS Location permission granted and services enabled");
  try {
    final latLon = await getCurrentLocation();
    final location = await getPlaceAddress(latLon);
    await updateLocationFunction(
      context,
      latLon,
      location,
    );
    print("Location obtained and updated: ${latLon[0]}, ${latLon[1]}");
    await viewProfile(context);
  } catch (e) {
    print('Error getting location: $e');
    if (e.toString().contains('Location services are disabled')) {
      await showLocationServiceDialog(context);
    } else {
      showAnimatedSnackBar(context, str.snack_enable_loc);
    }
  }
}

requestExplorerLocationPermission(
  BuildContext context,
) async {
  final str = AppLocalizations.of(context)!;

  // Step 1: Check current permission status first
  LocationPermission permission = LocationPermission.denied;
  bool pluginAvailable = true;
  Position? position = await determinePosition();
  try {
    permission = await Geolocator.checkPermission();
    print("Current explorer location permission: $permission");
  } catch (e) {
    print("Error checking location permission in explorer: $e");
    if (e.toString().contains('MissingPluginException')) {
      print(
          "Explorer permission check failed - plugin not available, using fallback");
      pluginAvailable = false;
      // Set fallback coordinates for explorer
      final provider = Provider.of<DataProvider>(context, listen: false);
      provider.explorerLat = '23.5859'; // Muscat, Oman latitude
      provider.explorerLong = '58.4059'; // Muscat, Oman longitude
      return;
    }
    permission = LocationPermission.denied;
  }

  // Step 2: Request permission if not granted
  if (permission == LocationPermission.denied && pluginAvailable) {
    try {
      print("Requesting explorer location permission...");
      permission = await Geolocator.requestPermission();
      print("Explorer permission request result: $permission");
    } catch (e) {
      print("Error requesting location permission in explorer: $e");
      if (e.toString().contains('MissingPluginException')) {
        print(
            "Explorer permission request failed - plugin not available, using fallback");
        // Set fallback coordinates for explorer
        final provider = Provider.of<DataProvider>(context, listen: false);
        provider.explorerLat = '23.5859'; // Muscat, Oman latitude
        provider.explorerLong = '58.4059'; // Muscat, Oman longitude
        return;
      }
      permission = LocationPermission.denied;
    }
  }

  // Step 3: Handle permission results
  if (permission == LocationPermission.denied) {
    print('Explorer location permissions are denied');
    showAnimatedSnackBar(context, str.snack_enable_loc);
    // Set fallback coordinates for explorer
    final provider = Provider.of<DataProvider>(context, listen: false);
    provider.explorerLat = '23.5859'; // Muscat, Oman latitude
    provider.explorerLong = '58.4059'; // Muscat, Oman longitude
    return;
  } else if (permission == LocationPermission.deniedForever) {
    print("Explorer location permissions are permanently denied");
    showAnimatedSnackBar(context, str.snack_enable_loc);
    // Set fallback coordinates for explorer
    final provider = Provider.of<DataProvider>(context, listen: false);
    provider.explorerLat = '23.5859'; // Muscat, Oman latitude
    provider.explorerLong = '58.4059'; // Muscat, Oman longitude
    return;
  }

  // Step 4: Permission granted, now check if location services are enabled
  bool serviceEnabled = false;
  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Explorer location service enabled: $serviceEnabled");
  } catch (e) {
    print("Error checking location service status in explorer: $e");
    if (e.toString().contains('MissingPluginException')) {
      print(
          "Explorer location service check failed - plugin not available, using fallback");
      // Set fallback coordinates for explorer
      final provider = Provider.of<DataProvider>(context, listen: false);
      provider.explorerLat = '23.5859'; // Muscat, Oman latitude
      provider.explorerLong = '58.4059'; // Muscat, Oman longitude
      return;
    }
    serviceEnabled = false;
  }

  // Step 5: If location services disabled, show dialog to enable
  if (!serviceEnabled && pluginAvailable) {
    print("Explorer location services disabled - showing dialog");
    await showLocationServiceDialog(context);
    return;
  }

  // Step 6: Both permission granted and services enabled - get location
  print("Explorer GPS Location permission granted and services enabled");
  try {
    if (position != null) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      provider.explorerLat = position.latitude.toString();
      provider.explorerLong = position.longitude.toString();
      print(
          "Explorer location obtained: ${provider.explorerLat}, ${provider.explorerLong}");
    } else {
      print("Position is null, using fallback coordinates");
      final provider = Provider.of<DataProvider>(context, listen: false);
      provider.explorerLat = '23.5859'; // Muscat, Oman latitude
      provider.explorerLong = '58.4059'; // Muscat, Oman longitude
    }
  } catch (e) {
    print('Error getting explorer location: $e');
    if (e.toString().contains('Location services are disabled')) {
      await showLocationServiceDialog(context);
    } else {
      showAnimatedSnackBar(context, str.snack_enable_loc);
      // Set fallback coordinates for explorer
      final provider = Provider.of<DataProvider>(context, listen: false);
      provider.explorerLat = '23.5859'; // Muscat, Oman latitude
      provider.explorerLong = '58.4059'; // Muscat, Oman longitude
    }
  }
}

sendCurrentLocation(BuildContext context) async {
  Position? position = await determinePosition();
  String latlonString;

  if (position != null) {
    latlonString = "${position.latitude},${position.longitude}";
    print("Using actual location: $latlonString");
  } else {
    // Use fallback coordinates if position is null
    latlonString = "23.5859,58.4059"; // Muscat, Oman
    print("Using fallback location: $latlonString");
  }

  await sendLocation(context, latlonString);
  // searchController.text.isEmpty ? getCurrentLocation() : null;
}

sendLocation(context, String latLon) async {
  final provider = Provider.of<DataProvider>(context, listen: false);
  final receiverId = provider.serviceManDetails?.userData?.id.toString();
  final str = AppLocalizations.of(context)!;
  provider.subServicesModel = null;
  final apiToken = Hive.box("token").get('api_token');
  final url =
      '$api/chat-store?receiver_id=$receiverId&type=location&message=$latLon&page=1';

  print(url);

  provider.isLocationSending = true;
  print(provider.isLocationSending);
  // return;
  try {
    var response = await http.post(Uri.parse(url),
        headers: {"device-id": provider.deviceId ?? '', "api-token": apiToken});
    if (response.statusCode == 200) {
      // var jsonResponse = jsonDecode(response.body);
      log("Location sended successfully");
      provider.isSendingSuccessFull = true;
      log(response.body);
      // final servicerProvider =
      //     Provider.of<ServicerProvider>(context, listen: false);
    } else {
      showAnimatedSnackBar(context, str.snack_message_sent);
    }
  } on Exception catch (e) {
    showAnimatedSnackBar(context, str.snack_message_sent);
    print(e);
  }
}

Future<List<double>> getCurrentLocationPermission(
  BuildContext context,
) async {
  log('permission request send for location----------------------------------------------------');
  late List<double> latLon;
  LocationPermission permission = LocationPermission.denied;
  try {
    permission = await Geolocator.checkPermission();
  } catch (e) {
    print(
        "Error checking location permission in getCurrentLocationPermission: $e");
    permission = LocationPermission.denied;
  }

  final str = AppLocalizations.of(context)!;
  if (permission == LocationPermission.denied) {
    try {
      permission = await Geolocator.requestPermission();
    } catch (e) {
      print(
          "Error requesting location permission in getCurrentLocationPermission: $e");
      permission = LocationPermission.denied;
    }
    if (permission == LocationPermission.denied) {
      log('Location permissions are denied');
    } else if (permission == LocationPermission.deniedForever) {
      log("'Location permissions are permanently denied");
      showAnimatedSnackBar(context, str.snack_enable_loc);
    } else {
      log("GPS Location service is granted");
      latLon = await getCurrentLocation();
      // final location = await getPlaceAddress(latLon);
      final latlonString = "${latLon[0]},${latLon[1]}";
      print(latlonString);
      return latLon;
    }
    return [0, 0];
  } else {
    log("GPS Location permission granted.");
    latLon = await getCurrentLocation();
    // final location = await getPlaceAddress(latLon);
    final latlonString = "${latLon[0]},${latLon[1]}";
    print(latlonString);

    return latLon;
  }

  // searchController.text.isEmpty ? getCurrentLocation() : null;
}

Future<List<double>> getCurrentLocation() async {
  List<double> latLon = [];

  // Check if location services are enabled with error handling
  bool serviceEnabled = false;
  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
  } catch (e) {
    print("Error checking location service status in getCurrentLocation: $e");
    // Assume services are disabled if we can't check
    serviceEnabled = false;
  }

  if (!serviceEnabled) {
    // Location services are disabled, ask user to enable them
    throw Exception(
        'Location services are disabled. Please enable location services in your device settings.');
  }

  try {
    Position? position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    ));
    double latitude = position.latitude;
    double longitude = position.longitude;
    latLon.addAll([latitude, longitude]);
  } catch (e) {
    print('Error getting current location: $e');
    throw e;
  }

  return latLon;
}

Future<String> getPlaceAddress(List<double> latLon) async {
  String locationAddress = '';
  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latLon[0], latLon[1]);

    locationAddress = getLocationName(placemarks);
  } catch (error) {
    print(error);
  }
  return locationAddress;
}

String getLocationName(List<Placemark> placemarks) {
  String locality = '';
  if (placemarks[0].subLocality!.isNotEmpty) {
    locality = '${placemarks[0].subLocality} | ${placemarks[0].country}';
  } else if (placemarks[0].locality!.isNotEmpty) {
    locality = '${placemarks[0].locality} | ${placemarks[0].country}';
  } else if (placemarks[0].street!.isNotEmpty) {
    locality = '${placemarks[0].street} | ${placemarks[0].country}';
  } else if (placemarks[0].subAdministrativeArea!.isNotEmpty) {
    locality =
        '${placemarks[0].subAdministrativeArea} | ${placemarks[0].country}';
  } else if (placemarks[0].administrativeArea!.isNotEmpty) {
    locality = '${placemarks[0].administrativeArea} | ${placemarks[0].country}';
  } else if (placemarks[0].name!.isNotEmpty) {
    locality = '${placemarks[0].name} | ${placemarks[0].country}';
  } else {}
  print(locality);
  return locality;
}

// Dialog to ask user to enable location services
// Returns true if user chose to open settings, false if cancelled
Future<bool> showLocationServiceDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must tap button
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Icon(
          Icons.location_off,
          size: 48,
          color: Colors.red,
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'Location Services Disabled',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This app needs location services to work properly. Please enable location services in your device settings.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Continue Without Location'),
            onPressed: () {
              Navigator.of(context).pop(false); // Return false for cancel
            },
          ),
          ElevatedButton(
            child: Text('Open Settings'),
            onPressed: () async {
              Navigator.of(context).pop(true); // Return true for open settings
              // Open location settings with comprehensive error handling
              try {
                await Geolocator.openLocationSettings();
                print("Successfully opened location settings");
              } catch (e) {
                print("Error opening location settings from dialog: $e");
                // If geolocator plugin fails, show user guidance
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Please manually enable location services in your device settings'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
          ),
        ],
      );
    },
  );

  return result ?? false; // Default to false if dialog is dismissed
}
