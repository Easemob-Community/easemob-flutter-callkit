package com.example.callkit.easemob_flutter_callkit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册 CallKit 插件
        CallKitPlugin.registerWith(flutterEngine, this)
    }
}
