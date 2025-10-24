// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tuw_services/API/endpoint.dart';
import 'package:tuw_services/API/home/get_service_man.dart';
import 'package:tuw_services/components/routes_manager.dart';
import 'package:tuw_services/model/get_home.dart';
import 'package:tuw_services/model/sub_services_model.dart';
import 'package:tuw_services/providers/data_provider.dart';
import 'package:tuw_services/screens/sub_service.dart';
import 'package:tuw_services/utils/get_location.dart';

getSubService(
    BuildContext context, int? id, bool changeLan, Services homeService) async {
  final provider = Provider.of<DataProvider>(context, listen: false);
  // provider.subServicesModel = null;
  String? apiToken = Hive.box("token").get('api_token');
  final String lanId = Hive.box("LocalLan").get('lang_id');

  // if (apiToken == null) return;
  if (apiToken == null) {
    apiToken = '';
  }
  try {
    var response = await http.post(
        Uri.parse('$subServices?parent_service_id=$id&language_id=$lanId'),
        headers: {"device-id": provider.deviceId ?? '', "api-token": apiToken});
    log(response.request.toString());
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      log(response.body);
      if (jsonResponse['result'] == false) {
        await Hive.box("token").clear();
        return;
      }
      print(jsonResponse['type']);
      if (changeLan != true) {
        selectServiceType(context, id ?? 0, jsonResponse, homeService);
      }
    } else {
      // print('Something went wrong');
    }
  } on Exception catch (_) {}
}

selectServiceType(BuildContext context, int id,
    Map<String, dynamic> jsonResponse, Services homeService) async {
  log('selectServiceType');
  final provider = Provider.of<DataProvider>(context, listen: false);
  if (jsonResponse['type'] == 'service') {
    final subServicesData = SubServicesModel.fromJson(jsonResponse);
    log('homeService------${homeService}');
    provider.subServicesModelData(subServicesData);
    Navigator.pushReplacement(context,
        FadePageRoute(page: SubServicesPage(homeService: homeService)));
  }
  //  else if (provider.viewProfileModel?.userdetails?.latitude == null &&
  //     provider.explorerLat == null)
  // {
  //   String? apiToken = Hive.box("token").get('api_token');
  //   if (apiToken == null) {
  //     requestExplorerLocationPermission(context);
  //   } else {
  //     requestLocationPermission(
  //       context,
  //     );
  //   }

  //   Navigator.pop(context);

  // AnimatedSnackBar.material(str.snack_get_location,
  //         type: AnimatedSnackBarType.info,
  //         borderRadius: BorderRadius.circular(6),
  //         duration: const Duration(seconds: 1))
  //     .show(
  //   context,
  // );
  // await Future.delayed(const Duration(seconds: 2));

  // AnimatedSnackBar.material(str.snack_done,
  //         type: AnimatedSnackBarType.success,
  //         borderRadius: BorderRadius.circular(6),
  //         duration: const Duration(seconds: 3))
  //     .show(
  //   context,
  // );
  // }
  else {
    // Get location once and pass it to getServiceMan to avoid duplicate requests
    print("🔍 Getting location for service man API...");
    // final locationData = await getCurrentLocationPermission();
    await getServiceMan(context, id, homeService, providedLocation: null);
    // log('message--2');

    // // Step 1: Check current permission status first
    // LocationPermission permission = LocationPermission.denied;
    // bool pluginAvailable = true;

    // try {
    //   permission = await Geolocator.checkPermission();
    //   print("Current location permission in selectServiceType: $permission");
    // } catch (e) {
    //   print("Error checking location permission in selectServiceType: $e");
    //   if (e.toString().contains('MissingPluginException')) {
    //     print(
    //         "Permission check failed in selectServiceType - plugin not available");
    //     pluginAvailable = false;
    //     // Continue with getServiceMan using fallback coordinates
    //     await getServiceMan(context, id, homeService);
    //     return;
    //   }
    //   permission = LocationPermission.denied;
    // }

    // // Step 2: Request permission if not granted
    // if (permission == LocationPermission.denied && pluginAvailable) {
    //   try {
    //     print("Requesting location permission in selectServiceType...");
    //     permission = await Geolocator.requestPermission();
    //     print("Permission request result in selectServiceType: $permission");
    //   } catch (e) {
    //     print("Error requesting location permission in selectServiceType: $e");
    //     if (e.toString().contains('MissingPluginException')) {
    //       print(
    //           "Permission request failed in selectServiceType - plugin not available");
    //       // Continue with getServiceMan using fallback coordinates
    //       await getServiceMan(context, id, homeService);
    //       return;
    //     }
    //     permission = LocationPermission.denied;
    //   }
    // }

    // // Step 3: Handle permission results
    // bool permissionGranted = (permission == LocationPermission.whileInUse ||
    //     permission == LocationPermission.always);

    // if (!permissionGranted) {
    //   print(
    //       'Location permissions denied in selectServiceType, using fallback coordinates');
    //   // Continue with getServiceMan using fallback coordinates
    //   await getServiceMan(context, id, homeService);
    //   return;
    // }

    // // Step 4: Permission granted, now check if location services are enabled
    // bool serviceEnabled = false;
    // try {
    //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
    //   print("Location service enabled in selectServiceType: $serviceEnabled");
    // } catch (e) {
    //   print("Error checking location service status in selectServiceType: $e");
    //   if (e.toString().contains('MissingPluginException')) {
    //     print(
    //         "Location service check failed in selectServiceType - plugin not available");
    //     // Continue with getServiceMan using fallback coordinates
    //     await getServiceMan(context, id, homeService);
    //     return;
    //   }
    //   serviceEnabled = false;
    // }

    // print(
    //     "Plugin available: $pluginAvailable, Service enabled: $serviceEnabled");

    // // Step 5: If location services disabled, show dialog to enable
    // if (!serviceEnabled && pluginAvailable) {
    //   print("Location services disabled in selectServiceType - showing dialog");
    //   final userWantsToOpenSettings = await showLocationServiceDialog(context);

    //   if (userWantsToOpenSettings) {
    //     // User chose to open settings, check if location is now enabled
    //     try {
    //       serviceEnabled = await Geolocator.isLocationServiceEnabled();
    //       print(
    //           "Location service status after settings in selectServiceType: $serviceEnabled");
    //     } catch (e) {
    //       print(
    //           "Error checking location service status after settings in selectServiceType: $e");
    //       serviceEnabled = false;
    //     }
    //   }
    // }

    // If plugin is not available OR service is enabled, continue with getServiceMan
  }
}
