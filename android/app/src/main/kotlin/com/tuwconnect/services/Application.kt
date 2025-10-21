package com.tuwconnect.services

import android.app.Application

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Flutter handles plugin registration automatically
    }
}