package com.tuwconnect.services

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.util.Base64
import android.util.Log
import com.google.android.gms.auth.api.phone.SmsRetriever as GoogleSmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.util.*

class SmsRetrieverPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var context: Context? = null
    private var eventSink: EventChannel.EventSink? = null
    private var smsReceiver: BroadcastReceiver? = null

    companion object {
        private const val TAG = "SmsRetrieverPlugin"
        private const val CHANNEL = "sms_retriever"
        private const val EVENT_CHANNEL = "sms_retriever_events"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        stopSmsRetriever()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAppSignature" -> {
                val signature = getAppSignature()
                result.success(signature)
            }
            "startSmsRetriever" -> {
                val success = startSmsRetriever()
                result.success(success)
            }
            "stopSmsRetriever" -> {
                stopSmsRetriever()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startSmsRetriever()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopSmsRetriever()
    }

    private fun getAppSignature(): String? {
        return try {
            val packageName = context?.packageName ?: return null
            val packageManager = context?.packageManager ?: return null
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            
            for (signature in packageInfo.signatures ?: emptyArray()) {
                val md = MessageDigest.getInstance("SHA-256")
                md.update(signature.toByteArray())
                val hashSignature = md.digest()
                
                val appInfo = "$packageName ${Base64.encodeToString(hashSignature, Base64.NO_PADDING or Base64.NO_WRAP)}"
                val hash = MessageDigest.getInstance("SHA-256")
                hash.update(appInfo.toByteArray(StandardCharsets.UTF_8))
                val hashBytes = hash.digest()
                val base64Hash = Base64.encodeToString(hashBytes, Base64.NO_PADDING or Base64.NO_WRAP or Base64.URL_SAFE)
                
                return base64Hash.substring(0, 11)
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app signature", e)
            null
        }
    }

    private fun startSmsRetriever(): Boolean {
        val currentActivity = activity ?: return false
        
        try {
            val client = GoogleSmsRetriever.getClient(currentActivity)
            val task = client.startSmsRetriever()
            
            task.addOnSuccessListener { _ ->
                Log.d(TAG, "SMS Retriever started successfully")
                registerSmsReceiver()
            }

            task.addOnFailureListener { exception: Exception ->
                Log.e(TAG, "Failed to start SMS Retriever", exception)
            }
            
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error starting SMS Retriever", e)
            return false
        }
    }

    private fun registerSmsReceiver() {
        if (smsReceiver != null) return
        
        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (GoogleSmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {
                    val extras = intent.extras
                    val status = extras?.get(GoogleSmsRetriever.EXTRA_STATUS) as Status

                    when (status.statusCode) {
                        CommonStatusCodes.SUCCESS -> {
                            val message = extras.getString(GoogleSmsRetriever.EXTRA_SMS_MESSAGE)
                            Log.d(TAG, "SMS retrieved: $message")
                            message?.let {
                                eventSink?.success(it)
                            }
                        }
                        CommonStatusCodes.TIMEOUT -> {
                            Log.d(TAG, "SMS Retriever timeout")
                            eventSink?.error("TIMEOUT", "SMS Retriever timeout", null)
                        }
                    }
                }
            }
        }

        val intentFilter = IntentFilter(GoogleSmsRetriever.SMS_RETRIEVED_ACTION)

        // Register receiver with RECEIVER_NOT_EXPORTED for Android 13+ compatibility
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            activity?.registerReceiver(smsReceiver, intentFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            activity?.registerReceiver(smsReceiver, intentFilter)
        }
    }

    private fun stopSmsRetriever() {
        smsReceiver?.let { receiver ->
            try {
                activity?.unregisterReceiver(receiver)
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering SMS receiver", e)
            }
            smsReceiver = null
        }
    }
}
