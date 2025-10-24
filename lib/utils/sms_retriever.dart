import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// SMS Retriever API implementation for Google Play Protect compliance
/// This replaces the need for READ_SMS and RECEIVE_SMS permissions
class SmsRetriever {
  static const MethodChannel _methodChannel = MethodChannel('sms_retriever');
  static const EventChannel _eventChannel =
      EventChannel('sms_retriever_events');

  /// Get the app signature hash for SMS Retriever API
  /// This is required for the SMS to be automatically detected
  static Future<String?> getAppSignature() async {
    if (!Platform.isAndroid) return null;

    try {
      final String? signature =
          await _methodChannel.invokeMethod('getAppSignature');
      return signature;
    } on PlatformException catch (e) {
      print("Error getting app signature: ${e.message}");
      return null;
    }
  }

  /// Start listening for SMS using SMS Retriever API
  /// This doesn't require any permissions
  static Future<bool> startSmsRetriever() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool result =
          await _methodChannel.invokeMethod('startSmsRetriever');
      return result;
    } on PlatformException catch (e) {
      print("Error starting SMS retriever: ${e.message}");
      return false;
    }
  }

  /// Listen for SMS code using SMS Retriever API
  /// Returns a stream of SMS messages
  static Stream<String> get smsStream {
    if (!Platform.isAndroid) {
      return Stream.empty();
    }

    return _eventChannel
        .receiveBroadcastStream()
        .map<String>((dynamic event) => event.toString());
  }

  /// Extract OTP code from SMS message
  /// This is a helper method to extract 4-6 digit codes
  static String? extractOtpFromSms(String sms) {
    // Look for 4-6 digit numbers in the SMS
    final RegExp otpRegex = RegExp(r'\b\d{4,6}\b');
    final Match? match = otpRegex.firstMatch(sms);
    return match?.group(0);
  }

  /// Stop listening for SMS
  static Future<void> stopSmsRetriever() async {
    if (!Platform.isAndroid) return;

    try {
      await _methodChannel.invokeMethod('stopSmsRetriever');
    } on PlatformException catch (e) {
      print("Error stopping SMS retriever: ${e.message}");
    }
  }
}

/// Alternative manual OTP input widget
/// This provides a fallback when SMS Retriever API is not available
class ManualOtpInput {
  /// Show a dialog for manual OTP entry
  /// This is used as a fallback when automatic SMS detection fails
  static Future<String?> showManualOtpDialog(context) async {
    // Implementation would show a dialog for manual OTP entry
    // This is a placeholder - you can implement the actual dialog
    return null;
  }
}
