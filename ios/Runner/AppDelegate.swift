import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 【说明】IM SDK 初始化已移至 Flutter 层，使用 easemob_im_sdk 插件初始化
    // 参考: https://doc.easemob.com/document/flutter/initialization.html
    //
    // Dart 层初始化代码：
    // EMOptions options = EMOptions(appKey: "your-app-key");
    // await EMClient.getInstance.init(options);
    
    // 1. 注册 Flutter 插件
    GeneratedPluginRegistrant.register(with: self)
    
    // 2. 注册 CallKit 插件
    if let registrar = self.registrar(forPlugin: "CallKitPlugin") {
        CallKitPlugin.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
