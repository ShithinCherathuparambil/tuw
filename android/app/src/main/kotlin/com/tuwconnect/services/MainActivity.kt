package com.tuwconnect.services

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register SMS Retriever Plugin
        flutterEngine.plugins.add(SmsRetrieverPlugin())
    }
}