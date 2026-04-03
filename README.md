# Flutter CallKit 集成指南

本文档是环信（Easemob）CallKit SDK 在 Flutter 中集成的完整指南，涵盖项目概述、环境配置、核心实现、常见问题及解决方案。

---

## 📋 项目概述

本项目是一个 **Flutter 音视频通话应用**，集成了环信 CallKit SDK，支持 Android 和 iOS 双平台，实现了基础的 1v1 音视频通话功能。

### 实现功能

| 功能 | Android | iOS | 说明 |
|------|---------|-----|------|
| 初始化 CallKit | ✅ | ✅ | 初始化 CallKit SDK |
| 账号密码登录 | ✅ | ✅ | EMClient 登录 |
| 发起音频通话 | ✅ | ✅ | 1v1 语音通话 |
| 发起视频通话 | ✅ | ✅ | 1v1 视频通话 |
| 接听/拒绝通话 | ✅ | ✅ | 来电处理（原生 UI）|
| 通话事件监听 | ✅ | ✅ | 事件流转发到 Flutter |
| 结束通话 | ✅ | ✅ | 挂断通话 |

---

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Android SDK 24+
- iOS 15.0+
- 环信 CallKit SDK（本地路径）

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd easemob_flutter_callkit
```

### 2. 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 环信 IM SDK（必须）
  easemob_im_sdk: ^4.5.0  # 请使用最新版本
```

然后获取依赖：

```bash
flutter pub get
```

### 3. 配置 App Key

修改 `lib/main.dart` 中的 App Key：

```dart
EMOptions options = EMOptions(
  appKey: "your-org#your-app",  // 替换为你的 App Key
  // ...
);
```

### 4. 运行

```bash
# Android
flutter run

# iOS
flutter run -d "设备名"
```

---

## 📁 项目结构

```
easemob-flutter-callkit/
├── lib/                              # Dart 代码
│   ├── main.dart                     # 主应用入口（简化 UI）
│   └── callkit.dart                  # CallKit Dart API 封装
│
├── android/                          # Android 原生代码
│   ├── app/src/main/kotlin/com/example/callkit/easemob_flutter_callkit/
│   │   ├── CallKitApplication.kt     # Application 类（IM SDK 初始化已移除）
│   │   ├── MainActivity.kt           # 主 Activity（注册插件）
│   │   └── CallKitPlugin.kt          # MethodChannel 插件实现
│   ├── settings.gradle               # 引入本地 CallKit 模块
│   └── app/build.gradle              # 依赖配置
│
├── ios/                              # iOS 原生代码
│   ├── Runner/
│   │   ├── AppDelegate.swift         # 应用代理（IM SDK 初始化已移除）
│   │   ├── CallKitPlugin.swift       # MethodChannel 插件实现
│   │   ├── Info.plist                # 权限配置
│   │   └── Assets.xcassets/          # 图标资源
│   └── Podfile                       # 引入 EaseCallUIKit
│
├── README.md                         # 快速开始指南
└── INTEGRATION_GUIDE.md              # 本文件（完整集成指南）
```

---

## ⚠️ 重要说明

### IM SDK 初始化方式

**仅在 Flutter 层初始化**，原生层（Android/iOS）不需要初始化。

```
Flutter 层: EMClient.getInstance.init() 
    ↓
Flutter 层: EMClient.getInstance.login()
    ↓
Flutter 层: CallKit.init()
```

### 为什么 CallKit 不需要 appKey

- **IM SDK 已在 Flutter 层初始化** - `EMClient.getInstance.init(options)` 已包含 `appKey` 和 `enableLog`
- **CallKitConfig 没有这些属性** - 原生 SDK 的 `CallKitConfig` 类不包含 `appKey` 和 `enableLog`
- **CallKit 复用已初始化的 IM SDK** - 不需要重复配置

---

## 🔑 核心流程

```
┌─────────────────┐
│  1. 初始化 IM   │  ← EMClient.getInstance.init(options)
│     SDK         │      （包含 appKey、debugModel 等）
└────────┬────────┘
         ▼
┌─────────────────┐
│  2. 登录 IM     │  ← EMClient.getInstance.login(userId, password)
│     SDK         │
└────────┬────────┘
         ▼
┌─────────────────┐
│  3. 初始化      │  ← CallKit.init(CallConfig())
│     CallKit     │      （无需 appKey）
└────────┬────────┘
         ▼
┌─────────────────┐
│  4. 发起通话    │  ← CallKit.startAudioCall(calleeId)
└─────────────────┘
```

---

## 📝 完整集成代码

### main.dart

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easemob_im_sdk/easemob_im_sdk.dart';  // IM SDK
import 'callkit.dart';  // CallKit

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallKit Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CallKitDemoPage(),
    );
  }
}

class CallKitDemoPage extends StatefulWidget {
  const CallKitDemoPage({super.key});

  @override
  State<CallKitDemoPage> createState() => _CallKitDemoPageState();
}

class _CallKitDemoPageState extends State<CallKitDemoPage> {
  String _status = '未初始化';
  StreamSubscription<CallEvent>? _eventSubscription;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _calleeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenCallEvents();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _userIdController.dispose();
    _passwordController.dispose();
    _calleeController.dispose();
    super.dispose();
  }

  /// 监听通话事件
  void _listenCallEvents() {
    _eventSubscription = CallKit.callEvents.listen((event) {
      print('收到通话事件: $event');
      setState(() {
        _status = '事件: ${event.type}';
      });
    });
  }

  /// ============================================
  /// 第 1 步：初始化 Flutter IM SDK
  /// ============================================
  Future<void> _initIMSDK() async {
    try {
      // 配置 IM SDK 选项
      EMOptions options = EMOptions(
        appKey: "easemob-demo#support",  // ⚠️ 替换为你的 App Key
        autoLogin: false,                 // 是否自动登录
        debugModel: true,                 // 是否开启调试模式
      );

      // 初始化 IM SDK
      await EMClient.getInstance.init(options);
      
      setState(() {
        _status = 'IM SDK 初始化成功';
      });
    } on EMError catch (e) {
      setState(() {
        _status = 'IM SDK 初始化失败: ${e.description}';
      });
    }
  }

  /// ============================================
  /// 第 2 步：登录 IM SDK
  /// ============================================
  Future<void> _loginIM() async {
    try {
      final userId = _userIdController.text.trim();
      final password = _passwordController.text.trim();

      if (userId.isEmpty || password.isEmpty) {
        _showMessage('请输入用户 ID 和密码');
        return;
      }

      // 账号密码登录
      await EMClient.getInstance.login(userId, password);
      
      setState(() {
        _status = 'IM SDK 登录成功: $userId';
      });
    } on EMError catch (e) {
      setState(() {
        _status = 'IM SDK 登录失败: ${e.description}';
      });
    }
  }

  /// ============================================
  /// 第 3 步：初始化 CallKit
  /// ============================================
  Future<void> _initCallKit() async {
    try {
      // 【注意】IM SDK 已在 Flutter 层初始化，CallKit 初始化不需要 appKey
      await CallKit.init(CallConfig());
      setState(() {
        _status = 'CallKit 初始化成功';
      });
    } catch (e) {
      setState(() {
        _status = 'CallKit 初始化失败: $e';
      });
    }
  }

  /// 发起音频通话
  Future<void> _startAudioCall() async {
    try {
      final calleeId = _calleeController.text.trim();
      if (calleeId.isEmpty) {
        _showMessage('请输入被叫用户 ID');
        return;
      }

      await CallKit.startAudioCall(calleeId);
      setState(() {
        _status = '正在呼叫: $calleeId';
      });
    } catch (e) {
      setState(() {
        _status = '呼叫失败: $e';
      });
    }
  }

  /// 发起视频通话
  Future<void> _startVideoCall() async {
    try {
      final calleeId = _calleeController.text.trim();
      if (calleeId.isEmpty) {
        _showMessage('请输入被叫用户 ID');
        return;
      }

      await CallKit.startVideoCall(calleeId);
      setState(() {
        _status = '正在视频呼叫: $calleeId';
      });
    } catch (e) {
      setState(() {
        _status = '呼叫失败: $e';
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('CallKit Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('状态: $_status', style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),

            // 第 1 步：初始化 IM SDK
            const Text('第 1 步：初始化 IM SDK', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _initIMSDK,
              child: const Text('初始化 IM SDK'),
            ),
            const SizedBox(height: 24),

            // 第 2 步：登录
            const Text('第 2 步：登录 IM SDK', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: '用户 ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loginIM,
              child: const Text('登录'),
            ),
            const SizedBox(height: 24),

            // 第 3 步：初始化 CallKit
            const Text('第 3 步：初始化 CallKit', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _initCallKit,
              child: const Text('初始化 CallKit'),
            ),
            const SizedBox(height: 24),

            // 发起通话
            const Text('发起通话', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _calleeController,
              decoration: const InputDecoration(
                labelText: '被叫用户 ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startAudioCall,
                    icon: const Icon(Icons.phone),
                    label: const Text('音频通话'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startVideoCall,
                    icon: const Icon(Icons.videocam),
                    label: const Text('视频通话'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔧 核心技术实现

### 1. 平台通道 (MethodChannel)

**Dart 层** (`lib/callkit.dart`):

```dart
static const MethodChannel _methodChannel = 
    MethodChannel('easemob_flutter_callkit');
static const EventChannel _eventChannel = 
    EventChannel('easemob_flutter_callkit/events');
```

**通信方法**:

| 方法名 | 说明 |
|--------|------|
| `init` | 初始化 CallKit |
| `login` | 账号密码登录 |
| `logout` | 登出 |
| `startCall` | 发起通话 |
| `answerCall` | 接听通话 |
| `rejectCall` | 拒绝通话 |
| `endCall` | 结束通话 |

---

### 2. Android 原生实现 (Kotlin)

#### 文件位置
- `android/app/src/main/kotlin/com/example/callkit/easemob_flutter_callkit/`

#### 核心类

**CallKitApplication.kt** - 应用入口

```kotlin
class CallKitApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // 【已注释】Flutter 层已集成 IM SDK，无需在原生初始化
        // initEMClient()  // REMOVED
    }
}
```

**CallKitPlugin.kt** - 插件实现

- 实现 `MethodCallHandler` 处理 Dart 调用
- 实现 `CallKitListener` 接收通话事件
- 使用 `mainHandler.post {}` 确保主线程回调

**核心方法**:

```kotlin
// 初始化
private fun handleInit(call: MethodCall, result: Result) {
    val appKey = call.argument<String>("appKey")  // 接收但不使用
    val enableLog = call.argument<Boolean>("enableLog") ?: false
    
    context?.let { ctx ->
        val config = CallKitConfig().apply {
            // Empty - CallKitConfig doesn't have appKey/enableLog properties
        }
        val success = CallKitClient.init(ctx, config)
        result.success(success)
    }
}

// 登录
private fun handleLogin(call: MethodCall, result: Result)

// 发起通话
private fun handleStartCall(call: MethodCall, result: Result)
```

---

### 3. iOS 原生实现 (Swift)

#### 文件位置
- `ios/Runner/`

#### 核心类

**AppDelegate.swift** - 应用代理

```swift
@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
        // 【已注释】Flutter 层已集成 IM SDK，无需在原生初始化
        
        GeneratedPluginRegistrant.register(with: self)
        if let registrar = self.registrar(forPlugin: "CallKitPlugin") {
            CallKitPlugin.register(with: registrar)
        }
        return super.application(...)
    }
}
```

**CallKitPlugin.swift** - 插件实现

- 实现 `FlutterPlugin` 协议
- 实现 `CallServiceListener` 协议接收通话事件
- 使用 `DispatchQueue.main.async` 切换主线程

**核心方法**:

```swift
// 初始化
private func handleInit(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let appKey = args["appKey"] as? String else {
        result(FlutterError(...))
        return
    }
    let enableLog = args["enableLog"] as? Bool ?? false  // 接收但不使用
    
    let config = CallKitConfig()  // No appKey/enableLog properties
    CallKitManager.shared.setup(config)
    CallKitManager.shared.addListener(self)
    result(nil)
}

// 登录（账号密码）
private func handleLogin(_ call: FlutterMethodCall, result: @escaping FlutterResult)

// 发起通话
private func handleStartCall(_ call: FlutterMethodCall, result: @escaping FlutterResult)
```

---

### 4. 线程处理

#### Android

```kotlin
// 主线程 Handler
private val mainHandler = Handler(Looper.getMainLooper())

// 确保回调在主线程
mainHandler.post {
    result.success(...)
}
```

#### iOS

```swift
// 切换到主线程
DispatchQueue.main.async {
    result(...)
}
```

---

## 📱 UI 界面

简洁的测试界面，包含以下模块：

### 1. 状态显示
- 显示当前操作状态（初始化、登录、通话等）

### 2. 初始化区域
- **初始化 CallKit** 按钮

### 3. 登录区域
- 用户 ID 输入框
- 密码输入框（已加密显示）
- **登录** 按钮

### 4. 通话区域
- 被叫用户 ID 输入框
- **音频通话** 按钮
- **视频通话** 按钮

---

## 🔑 关键 API

### IM SDK 初始化

```dart
EMOptions options = EMOptions(
  appKey: "your-app-key",  // 格式: orgName#appName
  autoLogin: false,
  debugModel: true,
);
await EMClient.getInstance.init(options);
```

### IM SDK 登录

```dart
// 账号密码登录
await EMClient.getInstance.login("userId", "password");

// Token 登录（可选）
await EMClient.getInstance.loginWithToken("userId", "token");
```

### IM SDK 登出

```dart
await EMClient.getInstance.logout(true);
```

### CallKit 初始化

```dart
// 【注意】IM SDK 已在 Flutter 层初始化，CallKit 初始化不需要 appKey
await CallKit.init(CallConfig(
  ringTimeOut: 30,              // 呼叫超时时间（秒）
  disableRTCTokenValidation: false,  // 是否禁用 RTC Token 验证
));
```

---

## 🔧 配置说明

### 1. 依赖配置

#### Android

**settings.gradle**:

```gradle
include ':ease-call-kit'
project(':ease-call-kit').projectDir = 
    new File('/Users/liupeng/Downloads/callkit/easemob-callkit-android-dev/ease-call-kit')
```

**app/build.gradle**:

```gradle
dependencies {
    implementation project(':ease-call-kit')
}
```

#### iOS

**Podfile**:

```ruby
# 本地 CallKit 路径
callkit_path = '/Users/liupeng/Downloads/callkit/easemob-callkit-iOS-dev'

target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # 本地 CallKit 依赖
  pod 'EaseCallUIKit', :path => callkit_path
end
```

---

### 2. 权限配置

#### Android

在 `AndroidManifest.xml` 中添加相机和麦克风权限：

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS

在 `Info.plist` 中添加：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机进行视频通话</string>
<key>NSMicrophoneUsageDescription</key>
<string>需要访问麦克风进行语音通话</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

---

## ⚠️ 常见问题与解决方案

### 问题 1: Android - NO_CONTEXT 错误

**现象**: `PlatformException(NO_CONTEXT, Context is null, null, null)`

**原因**: `CallKitPlugin` 实例创建后未初始化 Context

**解决方案**:

```kotlin
// 在 registerWith 中初始化 Context
@JvmStatic
fun registerWith(flutterEngine: FlutterEngine, context: Context) {
    val plugin = CallKitPlugin()
    plugin.initContext(context)  // 添加这一行
    // ...
}
```

---

### 问题 2: IM SDK 未初始化

**现象**: `PlatformException(IM_NOT_INITIALIZED, ...)`

**原因**: 调用 CallKit 方法前未初始化 EMClient

**解决方案**:

> **【已变更】** IM SDK 初始化已移至 **Flutter 层**，使用 `easemob_im_sdk` 插件初始化。

```dart
// 1. 在 Flutter 层初始化 IM SDK
EMOptions options = EMOptions(appKey: "easemob-demo#support");
await EMClient.getInstance.init(options);

// 2. 登录 IM SDK
await EMClient.getInstance.login("userId", "password");

// 3. 然后初始化 CallKit（无需 appKey，已在 IM SDK 初始化时配置）
await CallKit.init(CallConfig());
```

**如需恢复原生初始化**:
- **Android**: 取消 `CallKitApplication.onCreate()` 中的注释
- **iOS**: 取消 `AppDelegate.application()` 中的注释

---

### 问题 3: Android - 线程错误

**现象**: `Methods marked with @UiThread must be executed on the main thread`

**原因**: EMClient 回调在工作线程，直接调用 result 会崩溃

**解决方案**:

```kotlin
// 使用 Handler 切换到主线程
mainHandler.post {
    result.success(...)
}
```

---

### 问题 4: iOS - 模块找不到

**现象**: `No such module 'ChatClient'`

**原因**: Pod 名称为 `HyphenateChat` 而非 `ChatClient`

**解决方案**:

```swift
// 错误
import ChatClient

// 正确
import HyphenateChat
```

---

### 问题 5: iOS - 运行时崩溃

**现象**: `__abort_with_payload` / 信号量崩溃

**原因**: 缺少相机/麦克风权限声明

**解决方案**: 在 `Info.plist` 中添加权限声明（见上文配置说明）

---

### 问题 6: iOS - 类型不匹配

**现象**: `Type 'CallProfile' does not conform to protocol 'CallProfileProtocol'`

**原因**: `CallProfileProtocol` 要求继承 `NSObject` 且属性名不匹配

**解决方案**:

```swift
// 使用 SDK 提供的 CallUserProfile 类
let profile = CallUserProfile()
profile.id = userId
CallKitManager.shared.currentUserInfo = profile
```

---


### 登录方式

- ✅ 当前使用 **账号密码登录**
- ❌ 不支持 Token 登录（如需可自行修改）

### 平台限制

| 功能 | Android | iOS | 说明 |
|------|---------|-----|------|
| switchCamera | ⚠️ | ⚠️ | 内部 API，需通过 UI 操作 |
| enableVideo | ⚠️ | ⚠️ | 内部 API，需通过 UI 操作 |
| enableAudio | ⚠️ | ⚠️ | 内部 API，需通过 UI 操作 |
| enableSpeaker | ⚠️ | ⚠️ | 内部 API，需通过 UI 操作 |

---

## 🎯 测试步骤

1. **启动应用**
   ```bash
   flutter run
   ```

2. **初始化**
   - 点击 **"初始化 IM SDK"** 按钮
   - 等待显示 "IM SDK 初始化成功"

3. **登录**
   - 输入用户 ID
   - 输入密码
   - 点击 **"登录"** 按钮
   - 等待显示 "IM SDK 登录成功"

4. **初始化 CallKit**
   - 点击 **"初始化 CallKit"** 按钮
   - 等待显示 "CallKit 初始化成功"

5. **发起通话**
   - 输入被叫用户 ID
   - 点击 **"音频通话"** 或 **"视频通话"**

---

## 📝 注意事项

1. **真机测试**: 音视频功能必须在真机上测试，模拟器不支持
2. **网络权限**: 确保设备已连接网络
3. **权限授权**: iOS 首次使用需授权相机和麦克风权限
4. **后台运行**: iOS 需要开启后台音频模式以支持锁屏通话
5. **账号注册**: 测试前需在环信控制台注册测试账号
6. **App Key**: 从 [环信控制台](https://console.easemob.com/) 获取

---

## 🔗 参考资源

- [环信官方文档](https://doc.easemob.com/)
- [Flutter IM SDK 官方文档](https://doc.easemob.com/document/flutter/initialization.html)
- [Flutter IM SDK Pub 仓库](https://pub.dev/packages/easemob_im_sdk)
- [Flutter 平台通道](https://docs.flutter.dev/platform-integration/platform-channels)
- [EaseCallUIKit iOS](https://github.com/easemob/easemob-callkit-ios)
- [EaseCallUIKit Android](https://github.com/easemob/easemob-callkit-android)

---

## ✅ 项目状态

**已完成**: 双平台基础音视频通话功能

**测试状态**: ✅ 已通过基础功能测试

**适用场景**: 基础 1v1 音视频通话 Demo，可作为完整项目的基础框架

---

