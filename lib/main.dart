import 'dart:async';
import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
// 环信 IM SDK - 需要在 pubspec.yaml 中添加依赖: easemob_im_sdk: ^最新版本
import 'callkit.dart';

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
  bool _isIMInited = false; // IM SDK 是否已初始化
  bool _isLoggedIn = false; // 是否已登录
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
        appKey: "easemob-demo#support", // ⚠️ 替换为你的 App Key
        autoLogin: false, // 是否自动登录
      );

      // 初始化 IM SDK
      await EMClient.getInstance.init(options);

      setState(() {
        _isIMInited = true;
        _status = 'IM SDK 初始化成功';
      });

      _showMessage('IM SDK 初始化成功');
    } on EMError catch (e) {
      setState(() {
        _status = 'IM SDK 初始化失败: ${e.description}';
      });
      _showMessage('IM SDK 初始化失败: ${e.description}');
    }
  }

  /// ============================================
  /// 第 2 步：登录 IM SDK
  /// ============================================
  Future<void> _loginIM() async {
    // 检查 IM SDK 是否已初始化
    if (!_isIMInited) {
      _showMessage('请先初始化 IM SDK');
      return;
    }

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
        _isLoggedIn = true;
        _status = 'IM SDK 登录成功: $userId';
      });

      _showMessage('登录成功');
    } on EMError catch (e) {
      setState(() {
        _status = 'IM SDK 登录失败: ${e.description}';
      });
      _showMessage('登录失败: ${e.description}');
    }
  }

  /// ============================================
  /// 第 3 步：初始化 CallKit
  /// ============================================
  Future<void> _initCallKit() async {
    // 检查是否已登录
    if (!_isLoggedIn) {
      _showMessage('请先登录 IM SDK');
      return;
    }

    try {
      // 【注意】IM SDK 已在 Flutter 层初始化，CallKit 初始化不需要 appKey
      // 如需配置推送，请在 AndroidManifest.xml 和 Info.plist 中配置
      await CallKit.init(CallConfig());
      setState(() {
        _status = 'CallKit 初始化成功';
      });
      _showMessage('CallKit 初始化成功');
    } catch (e) {
      setState(() {
        _status = 'CallKit 初始化失败: $e';
      });
      _showMessage('初始化失败: $e');
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
      _showMessage('呼叫失败: $e');
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
      _showMessage('呼叫失败: $e');
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('状态: $_status', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isIMInited ? Icons.check_circle : Icons.cancel,
                          color: _isIMInited ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('IM SDK: ${_isIMInited ? "已初始化" : "未初始化"}'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          _isLoggedIn ? Icons.check_circle : Icons.cancel,
                          color: _isLoggedIn ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('登录状态: ${_isLoggedIn ? "已登录" : "未登录"}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 第 1 步：初始化 IM SDK
            const Text(
              '第 1 步：初始化 IM SDK',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isIMInited ? null : _initIMSDK,
              child: const Text('初始化 IM SDK'),
            ),
            const SizedBox(height: 24),

            // 第 2 步：登录
            const Text(
              '第 2 步：登录 IM SDK',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
              onPressed: _isLoggedIn ? null : _loginIM,
              child: const Text('登录'),
            ),
            const SizedBox(height: 24),

            // 第 3 步：初始化 CallKit
            const Text(
              '第 3 步：初始化 CallKit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _initCallKit,
              child: const Text('初始化 CallKit'),
            ),
            const SizedBox(height: 24),

            // 发起通话
            const Text(
              '发起通话',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
