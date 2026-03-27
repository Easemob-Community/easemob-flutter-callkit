package com.example.callkit.easemob_flutter_callkit

import android.app.Application

/**
 * CallKit Application
 * 
 * 【说明】IM SDK 初始化已移至 Flutter 层，使用 easemob_im_sdk 插件初始化
 * 参考: https://doc.easemob.com/document/flutter/initialization.html
 * 
 * 如需恢复原生初始化，请参考历史版本或文档
 */
class CallKitApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // 【已移除】Flutter 层已集成 IM SDK，无需在原生初始化
        // Dart 层初始化代码：
        // EMOptions options = EMOptions(appKey: "your-app-key");
        // await EMClient.getInstance.init(options);
    }
}
