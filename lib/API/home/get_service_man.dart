import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tuw_services/API/endpoint.dart';
import 'package:tuw_services/components/routes_manager.dart';
import 'package:tuw_services/model/get_home.dart';
import 'package:tuw_services/model/serviceManLIst.dart';
import 'package:tuw_services/providers/data_provider.dart';
import 'package:tuw_services/providers/servicer_provider.dart';
import 'package:tuw_services/screens/serviceman/servicer.dart';
import 'package:tuw_services/utils/get_location.dart';

/// Determine the current position of the device using only location package.
/// Uses native GPS enabling and permission requests for the best user experience.
/// Returns LocationData if successful, null if location services fail.
/// This provides native Android dialogs and maximum compatibility.
Future<loc.LocationData?> determinePosition() async {
  try {
    print(
        "🔍 Starting ENHANCED location determination with multiple methods...");
    print("🔧 DEBUG: determinePosition() called");

    print("🔧 DEBUG: Method 2 - Trying Location package...");
    try {
      final locationResult = await _tryLocationPackage();
      if (locationResult != null) {
        print("✅ SUCCESS: Location package provided real location!");
        return locationResult;
      }
    } catch (e) {
      print("⚠️ Location package failed: $e");
    }

    // Method 3: Use fallback coordinates
    print("🔧 DEBUG: Method 3 - Using fallback coordinates...");
    return null;
  } catch (e) {
    print("❌ Unexpected error in determinePosition: $e");
    return null;
  }
}

/// Try to get location using Location package (fallback)
Future<loc.LocationData?> _tryLocationPackage() async {
  try {
    print("🔧 DEBUG: Initializing Location package...");
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Check if location service is enabled
    try {
      serviceEnabled = await location.serviceEnabled();
      print("📡 Location package: Location services enabled: $serviceEnabled");
    } catch (e) {
      print("❌ Location package: Error checking location services: $e");
      return null;
    }

    // Request service if not enabled
    if (!serviceEnabled) {
      print("⚠️ Location package: Requesting to enable location services...");
      try {
        serviceEnabled = await location.requestService();
        print(
            "🔧 DEBUG: Location package service request result: $serviceEnabled");
        if (!serviceEnabled) {
          print(
              "❌ Location package: User declined to enable location services");
          return null;
        }

        // Wait for GPS to initialize after being enabled
        print("⏰ Waiting 3 seconds for GPS to initialize after enabling...");
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        print("❌ Location package: Error requesting location service: $e");
        return null;
      }
    }

    // Check permissions
    try {
      permissionGranted = await location.hasPermission();
      print("🔐 Location package: Permission status: $permissionGranted");
    } catch (e) {
      print("❌ Location package: Error checking permission: $e");
      return null;
    }

    // Request permission if needed
    if (permissionGranted == loc.PermissionStatus.denied) {
      try {
        print("🔧 DEBUG: Requesting Location package permission...");
        permissionGranted = await location.requestPermission();
        print(
            "🔧 DEBUG: Location package permission after request: $permissionGranted");
        if (permissionGranted != loc.PermissionStatus.granted &&
            permissionGranted != loc.PermissionStatus.grantedLimited) {
          print("❌ Location package: Permission not granted");
          return null;
        }
      } catch (e) {
        print("❌ Location package: Error requesting permission: $e");
        return null;
      }
    }

    print("✅ Location package: Permissions granted, getting position...");

    // Get location with timeout and proper error handling
    try {
      await location.changeSettings(
        accuracy: loc.LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 0,
      );

      loc.LocationData locationData = await location.getLocation().timeout(
        const Duration(seconds: 15), // Timeout to prevent hanging
        onTimeout: () {
          throw Exception("Location package timeout");
        },
      );

      if (locationData.latitude != null &&
          locationData.longitude != null &&
          locationData.latitude != 0.0 &&
          locationData.longitude != 0.0) {
        log('locationData------------------${locationData.latitude}------${locationData.longitude}');
        print(
            "📍 Location package SUCCESS: ${locationData.latitude}, ${locationData.longitude}");
        return locationData;
      } else {
        print("❌ Location package: Invalid coordinates received");
        return null;
      }
    } catch (e) {
      print("❌ Location package: Error getting position: $e");
      return null;
    }
  } catch (e) {
    print("❌ Location package: Unexpected error: $e");
    return null;
  }
}

Future<void> getServiceMan(BuildContext context, int? id, Services homeservice,
    {loc.LocationData? providedLocation}) async {
  // await determinePosition();
  log('getServiceMan ----------------------1');
  //  final otpProvider = Provider.of<OTPProvider>(context, listen: false);
  final provider = Provider.of<DataProvider>(context, listen: false);
  final userDetails = provider.viewProfileModel?.userdetails;
  log('getServiceMan ----------------------2');
  final String lanId = Hive.box("LocalLan").get('lang_id');
  log('getServiceMan ----------------------3');
  // provider.subServicesModel = null;
  String? apiToken = Hive.box("token").get('api_token');
  log('getServiceMan ----------------------4');
  // if (apiToken == null) return;
  if (apiToken == null) {
    log('getServiceMan ----------------------5');
    apiToken = '';
    log('getServiceMan ----------------------6');
  }
  try {
    // Use provided location if available, otherwise determine position
    loc.LocationData? locationData = await determinePosition();
    if (locationData == null) {
      locationData = await determinePosition();
      if (locationData == null) {
        locationData = providedLocation;
      }
    }
    log('getServiceMan ----------------------${locationData?.latitude} - ${locationData?.longitude}');
    log('user details -------- ${userDetails?.latitude}');

    double latitude = locationData?.latitude ??
        23.5859; // Default fallback coordinates (Muscat, Oman)
    double longitude = locationData?.longitude ?? 58.4059;

    // Step 4: Try to get current position if everything is available
    try {
      if (locationData != null) {
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

      if (jsonResponse['result'] == false) {
        await Hive.box("token").clear();
        return;
      }

      final serviceManListData = ServiceManListModel.fromJson(jsonResponse);
      provider.getServiceManData(serviceManListData);

      // Navigate to ServicerPage after successful API response
      log('navToServiceMan ----------------------1');
      navToServiceMan(context, id, homeservice, locationData);
      log('navToServiceMan ----------------------2');
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
