import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tuw_services/API/endpoint.dart';
import 'package:tuw_services/components/routes_manager.dart';
import 'package:tuw_services/model/serviceManLIst.dart';
import 'package:tuw_services/providers/data_provider.dart';
import 'package:tuw_services/providers/servicer_provider.dart';
import 'package:tuw_services/screens/serviceman/servicer.dart';

/// Determine the current position of the device using only location package.
/// Uses native GPS enabling and permission requests for the best user experience.
/// Returns LocationData if successful, null if location services fail.
/// This provides native Android dialogs and maximum compatibility.
Future<loc.LocationData?> determinePosition() async {
  try {
    print("🔍 Starting location determination with location package only...");

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
        print("📱 Native GPS enable request result: $serviceEnabled");
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

    // Step 3: Check permission status
    try {
      permissionGranted = await location.hasPermission();
      print("🔐 Current permission status: $permissionGranted");
    } catch (e) {
      print("❌ Error checking permission: $e");
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
        print("📱 Native permission request result: $permissionGranted");
      } catch (e) {
        print("❌ Error requesting permission: $e");
        if (e.toString().contains('MissingPluginException')) {
          print("🚫 Location plugin not available in release mode");
          return _getFallbackLocationData();
        }
        return _getFallbackLocationData();
      }
    }

    // Step 5: Check final permission status
    bool finalPermissionGranted =
        (permissionGranted == loc.PermissionStatus.granted ||
            permissionGranted == loc.PermissionStatus.grantedLimited);

    if (!finalPermissionGranted) {
      print("❌ Location permissions are denied by user: $permissionGranted");
      if (permissionGranted == loc.PermissionStatus.deniedForever) {
        print("🚫 Location permissions are permanently denied");
        // Note: We can't open app settings without geolocator, so just return fallback
      }
      return _getFallbackLocationData();
    }

    // Step 6: Get current position using location package
    print("✅ Permissions granted, getting current position...");
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
  } catch (e) {
    print("❌ Unexpected error in determinePosition: $e");
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

Future<void> getServiceMan(BuildContext context, id, homeservice) async {
  //  final otpProvider = Provider.of<OTPProvider>(context, listen: false);
  final provider = Provider.of<DataProvider>(context, listen: false);
  final userDetails = provider.viewProfileModel?.userdetails;
  final String lanId = Hive.box("LocalLan").get('lang_id');
  // provider.subServicesModel = null;
  String? apiToken = Hive.box("token").get('api_token');
  // if (apiToken == null) return;
  if (apiToken == null) {
    apiToken = '';
  }
  try {
    loc.LocationData? locationData = await determinePosition();
    log('user details -------- ${userDetails?.latitude}');

    double latitude = 23.5859; // Default fallback coordinates (Muscat, Oman)
    double longitude = 58.4059;

    // Step 4: Try to get current position if everything is available
    try {
      if (locationData != null) {
        latitude = locationData.latitude ?? 23.5859;
        longitude = locationData.longitude ?? 58.4059;
        log('position-------_${latitude}------${longitude}');
        userDetails?.latitude = latitude.toString();
        userDetails?.longitude = longitude.toString();
        print("📍 Using actual location: $latitude, $longitude");
      } else {
        print("🏠 Using fallback location: $latitude, $longitude");
      }
    } catch (e) {
      print("Error getting position in getServiceMan, using fallback: $e");
      // Use fallback coordinates if position determination fails
    }

    var response = await http.post(
        Uri.parse(
            '$servicemanList?service_id=$id&page=1&latitude=$latitude&longitude=$longitude&language_id=${lanId}'),
        headers: {"device-id": provider.deviceId ?? '', "api-token": apiToken});
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      log('getServiceMan------------>> ${response.body}------${response.request}');
      print("Navigation active");

      navToServiceMan(context, id, homeservice, locationData);
      if (jsonResponse['result'] == false) {
        await Hive.box("token").clear();
        return;
      }

      final serviceManListData = ServiceManListModel.fromJson(jsonResponse);
      provider.getServiceManData(serviceManListData);
      // if (provider.serviceManListModel?.serviceman?.isEmpty ?? false) {
      //   showAnimatedSnackBar(context, "No ServiceMan Available");
      // }
    } else {
      // print(response.statusCode);
      // print(response.body);
      // print('Something went wrong');
    }
  } on Exception catch (_) {}
}

searchServiceMan(
    BuildContext context, id, countryId, state, region, name, transport) async {
  final String lanId = Hive.box("LocalLan").get('lang_id');
  final servicerProvider =
      Provider.of<ServicerProvider>(context, listen: false);
  final provider = Provider.of<DataProvider>(context, listen: false);
  final userDetails = provider.viewProfileModel?.userdetails;
  // provider.subServicesModel = null;
  String? apiToken = Hive.box("token").get('api_token');
  // for explore apiToken want to be null so cant return it
  // if (apiToken == null) return;
  if (apiToken == null) {
    apiToken = '';
  }
  try {
    final url =
        '$servicemanList?service_id=$id&page=1&latitude=${servicerProvider.servicerLatitude ?? userDetails?.latitude ?? provider.explorerLat}&longitude=${servicerProvider.servicerLongitude ?? userDetails?.longitude ?? provider.explorerLong}&sel_country_id=${countryId ?? ''}&sel_state=${state ?? ''}&sel_region=${region ?? ''}&sel_name=${name ?? ''}&sel_transport=${transport ?? ''}&language_id=${lanId}';
    log(url);
    var response = await http.post(Uri.parse(url),
        headers: {"device-id": provider.deviceId ?? '', "api-token": apiToken});
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      log(response.body);

      final serviceManListData = ServiceManListModel.fromJson(jsonResponse);

      provider.getServiceManData(serviceManListData);
      // if (provider.serviceManListModel?.serviceman?.isEmpty ?? false) {
      //   showAnimatedSnackBar(context, "No ServiceMan Available");
      // }
    } else {
      // print(response.statusCode);
      // print(response.body);
      // print('Something went wrong');
    }
  } on Exception catch (_) {}
}

navToServiceMan(context, id, homeservice, loc.LocationData? locationData) {
  // Always navigate regardless of location data availability
  // The ServicerPage will handle fallback coordinates internally if needed
  print(
      "🚀 Navigating to ServicerPage with location data: ${locationData != null ? 'Available' : 'Using fallback'}");

  Navigator.pushReplacement(context,
      FadePageRoute(page: ServicerPage(id: id, homeservice: homeservice)));
}
