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

Future<Position?> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;
  await Geolocator.requestPermission();
  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    await Geolocator.openLocationSettings();
    return Future.error('Location services are disabled..');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
  // print("=== Starting determinePosition ===");

  // // Step 2: Check current permission status
  // LocationPermission permission = LocationPermission.denied;
  // try {
  //   permission = await Geolocator.checkPermission();
  //   print("Current location permission in determinePosition: $permission");
  // } catch (e) {
  //   print("Error checking location permission in determinePosition: $e");
  //   if (e.toString().contains('MissingPluginException')) {
  //     print(
  //         "Permission check failed in determinePosition - plugin not available, returning null");
  //     return null;
  //   }
  //   permission = LocationPermission.denied;
  // }

  // // Step 3: Request permission if not granted and plugin is available
  // if (permission == LocationPermission.denied) {
  //   try {
  //     print("Requesting location permission in determinePosition...");
  //     permission = await Geolocator.requestPermission();
  //     print("Permission request result in determinePosition: $permission");
  //   } catch (e) {
  //     print("Error requesting location permission in determinePosition: $e");
  //     if (e.toString().contains('MissingPluginException')) {
  //       print(
  //           "Permission request failed in determinePosition - plugin not available, returning null");
  //       return null;
  //     }
  //     permission = LocationPermission.denied;
  //   }
  // }

  // // Step 3: Handle permission results
  // if (permission == LocationPermission.denied) {
  //   try {
  //     await Geolocator.openLocationSettings();
  //   } catch (e) {
  //     print("Error opening location settings: $e");
  //   }
  //   print(
  //       'Location permissions are denied in determinePosition, returning null');
  //   return null; // Return null instead of throwing error
  // }

  // if (permission == LocationPermission.deniedForever) {
  //   try {
  //     await Geolocator.openLocationSettings();
  //   } catch (e) {
  //     print("Error opening location settings: $e");
  //   }
  //   print(
  //       'Location permissions are permanently denied in determinePosition, returning null');
  //   return null; // Return null instead of throwing error
  // }

  // // Step 4: Permission granted, now check if location services are enabled
  // bool serviceEnabled = false;
  // try {
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   print("Location service enabled in determinePosition: $serviceEnabled");
  // } catch (e) {
  //   print("Error checking location service status in determinePosition: $e");
  //   if (e.toString().contains('MissingPluginException')) {
  //     print(
  //         "Location service check failed in determinePosition - plugin not available, returning null");
  //     return null; // Return null instead of throwing error
  //   }
  //   serviceEnabled = false;
  // }

  // // Step 5: If location services disabled, return null
  // if (!serviceEnabled) {
  //   print("Location services disabled in determinePosition, returning null");
  //   return null; // Return null instead of throwing error
  // }

  // // Step 6: Both permission granted and services enabled - get position
  // try {
  //   print("Getting current position in determinePosition...");
  //   return await Geolocator.getCurrentPosition();
  // } catch (e) {
  //   print("Error getting current position in determinePosition: $e");
  //   if (e.toString().contains('MissingPluginException')) {
  //     print("getCurrentPosition failed - plugin not available, returning null");
  //     return null; // Return null instead of throwing error
  //   }
  //   print("getCurrentPosition failed with error: $e, returning null");
  //   return null; // Return null instead of throwing error
  // }
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
    Position? position = await determinePosition();
    log('user details -------- ${userDetails?.latitude}');

    double latitude = 23.5859; // Default fallback coordinates (Muscat, Oman)
    double longitude = 58.4059;

    // Step 4: Try to get current position if everything is available

    try {
      if (position == null) return;

      ;
      log('position-------_${position.latitude}------${position.longitude}');
      latitude = position.latitude;
      longitude = position.longitude;
      userDetails?.latitude = position.latitude.toString();
      userDetails?.longitude = position.longitude.toString();
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

      navToServiceMan(context, id, homeservice, position);
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

navToServiceMan(context, id, homeservice, Position? position) {
  if (position == null) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    return;
  }

  Navigator.pushReplacement(context,
      FadePageRoute(page: ServicerPage(id: id, homeservice: homeservice)));
}
