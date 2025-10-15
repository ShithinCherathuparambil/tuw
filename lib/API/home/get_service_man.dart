import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tuw_services/API/endpoint.dart';
import 'package:tuw_services/components/routes_manager.dart';
import 'package:tuw_services/model/serviceManLIst.dart';
import 'package:tuw_services/providers/data_provider.dart';
import 'package:tuw_services/providers/servicer_provider.dart';
import 'package:tuw_services/screens/serviceman/servicer.dart';

Future<Position> determinePosition() async {
  // Step 1: Check current permission status first
  LocationPermission permission = LocationPermission.denied;
  bool pluginAvailable = true;

  try {
    permission = await Geolocator.checkPermission();
    print("Current location permission in determinePosition: $permission");
  } catch (e) {
    print("Error checking location permission in determinePosition: $e");
    if (e.toString().contains('MissingPluginException')) {
      print(
          "Permission check failed in determinePosition - plugin not available");
      pluginAvailable = false;
      return Future.error('Location plugin not available in release mode');
    }
    permission = LocationPermission.denied;
  }

  // Step 2: Request permission if not granted
  if (permission == LocationPermission.denied && pluginAvailable) {
    try {
      print("Requesting location permission in determinePosition...");
      permission = await Geolocator.requestPermission();
      print("Permission request result in determinePosition: $permission");
    } catch (e) {
      print("Error requesting location permission in determinePosition: $e");
      if (e.toString().contains('MissingPluginException')) {
        print(
            "Permission request failed in determinePosition - plugin not available");
        return Future.error('Location plugin not available in release mode');
      }
      permission = LocationPermission.denied;
    }
  }

  // Step 3: Handle permission results
  if (permission == LocationPermission.denied) {
    return Future.error('Location permissions are denied');
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Step 4: Permission granted, now check if location services are enabled
  bool serviceEnabled = false;
  try {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("Location service enabled in determinePosition: $serviceEnabled");
  } catch (e) {
    print("Error checking location service status in determinePosition: $e");
    if (e.toString().contains('MissingPluginException')) {
      print(
          "Location service check failed in determinePosition - plugin not available");
      return Future.error('Location plugin not available in release mode');
    }
    serviceEnabled = false;
  }

  // Step 5: If location services disabled, return error
  if (!serviceEnabled && pluginAvailable) {
    print("Location services disabled in determinePosition");
    return Future.error(
        'Location services are disabled. Please enable location services in your device settings.');
  }

  // Step 6: Both permission granted and services enabled - get position
  try {
    print("Getting current position in determinePosition...");
    return await Geolocator.getCurrentPosition();
  } catch (e) {
    print("Error getting current position in determinePosition: $e");
    if (e.toString().contains('MissingPluginException')) {
      return Future.error('Location plugin not available in release mode');
    }
    return Future.error('Error getting current position: $e');
  }
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
    bool serviceEnabled = false;
    bool pluginAvailable = true;
    log('user details -------- ${userDetails?.latitude}');

    // Test if location services are enabled with error handling.
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print("Error checking location service status in getServiceMan: $e");
      serviceEnabled = false;
      pluginAvailable = false; // Plugin is not available
    }

    double latitude = 23.5859; // Default fallback coordinates (Muscat, Oman)
    double longitude = 58.4059;

    // Try to get current position if plugin is available and service is enabled
    if (pluginAvailable && serviceEnabled) {
      try {
        Position position = await determinePosition();
        log('position-------_${position.latitude}------${position.longitude}');
        latitude = position.latitude;
        longitude = position.longitude;
        userDetails?.latitude = position.latitude.toString();
        userDetails?.longitude = position.longitude.toString();
      } catch (e) {
        print("Error getting position in getServiceMan, using fallback: $e");
        // Use fallback coordinates if position determination fails
      }
    } else {
      print(
          "Location plugin not available or service disabled, using fallback coordinates");
      // Use existing user coordinates if available, otherwise use fallback
      if (userDetails?.latitude != null && userDetails?.longitude != null) {
        try {
          latitude = double.parse(userDetails!.latitude!);
          longitude = double.parse(userDetails!.longitude!);
          log('Using existing user coordinates: $latitude, $longitude');
        } catch (e) {
          print("Error parsing existing coordinates, using fallback: $e");
        }
      }
    }
    var response = await http.post(
        Uri.parse(
            '$servicemanList?service_id=$id&page=1&latitude=$latitude&longitude=$longitude&language_id=${lanId}'),
        headers: {"device-id": provider.deviceId ?? '', "api-token": apiToken});
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      log('getServiceMan------------>> ${response.body}------${response.request}');
      print("Navigation active");
      navToServiceMan(context, id, homeservice);
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

navToServiceMan(context, id, homeservice) {
  Navigator.pushReplacement(
      context,
      FadePageRoute(
          page: ServicerPage(
        id: id,
        homeservice: homeservice,
      )));
}
