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
import 'package:location/location.dart' as loc;

Future<Position> determinePosition() async {
  // Step 1: Check permission status
  LocationPermission permission;
  bool pluginAvailable = true;

  try {
    permission = await Geolocator.checkPermission();
    print("Current location permission: $permission");
  } catch (e) {
    print("Error checking location permission: $e");
    if (e.toString().contains('MissingPluginException')) {
      pluginAvailable = false;
      return Future.error('Location plugin not available in release mode');
    }
    permission = LocationPermission.denied;
  }

  // Step 2: Request permission if denied
  if (permission == LocationPermission.denied && pluginAvailable) {
    try {
      permission = await Geolocator.requestPermission();
    } catch (e) {
      print("Error requesting location permission: $e");
      return Future.error('Error requesting permission');
    }
  }

  if (permission == LocationPermission.denied) {
    await Geolocator.openAppSettings();
    return Future.error('Location permissions are denied');
  }

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
    return Future.error(
        'Location permissions are permanently denied, cannot request permissions.');
  }

  // Step 3: Check if location services are enabled
  final loc.Location location = loc.Location();

  bool serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    // 🔥 This shows the Android system dialog like Google Pay
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return Future.error(
          'Location services are disabled. Please enable them to continue.');
    }
  }

  // Step 4: All good, get current position
  try {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (e) {
    print("Error getting position: $e");
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
    log('user details -------- ${userDetails?.latitude}');

    double latitude = 23.5859; // Default fallback coordinates (Muscat, Oman)
    double longitude = 58.4059;

    // Step 4: Try to get current position if everything is available

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
