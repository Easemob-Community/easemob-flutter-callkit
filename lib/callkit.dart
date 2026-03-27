import 'dart:async';
import 'package:flutter/services.dart';

/// 通话类型
enum CallType {
  /// 音频通话
  audio(0),
  /// 视频通话
  video(1);

  final int value;
  const CallType(this.value);

  static CallType fromValue(int value) {
    return CallType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CallType.audio,
    );
  }
}

/// 通话状态
enum CallState {
  /// 空闲
  idle(0),
  /// 呼出中
  outgoing(1),
  /// 呼入中
  incoming(2),
  /// 连接中
  connecting(3),
  /// 通话中
  connected(4);

  final int value;
  const CallState(this.value);

  static CallState fromValue(int value) {
    return CallState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CallState.idle,
    );
  }
}

/// 通话事件
class CallEvent {
  final String type;
  final Map<String, dynamic>? data;

  CallEvent({required this.type, this.data});

  factory CallEvent.fromMap(Map<dynamic, dynamic> map) {
    return CallEvent(
      type: map['type'] as String,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  @override
  String toString() => 'CallEvent(type: $type, data: $data)';
}

/// 通话配置
/// 
/// 【注意】IM SDK 已在 Flutter 层初始化，CallKit 初始化不需要 appKey。
/// 此配置类保留用于后续扩展 CallKit 专用配置（如铃声、超时时间等）。
class CallConfig {
  /// 呼叫超时时间（秒），默认 30 秒
  final int ringTimeOut;
  /// 是否禁用 RTC Token 验证
  final bool disableRTCTokenValidation;

  CallConfig({
    this.ringTimeOut = 30,
    this.disableRTCTokenValidation = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'ringTimeOut': ringTimeOut,
      'disableRTCTokenValidation': disableRTCTokenValidation,
    };
  }
}

/// CallKit 管理类
class CallKit {
  static const MethodChannel _methodChannel = MethodChannel('easemob_flutter_callkit');
  static const EventChannel _eventChannel = EventChannel('easemob_flutter_callkit/events');

  static Stream<CallEvent>? _callEventsStream;

  /// 通话事件流
  static Stream<CallEvent> get callEvents {
    _callEventsStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => CallEvent.fromMap(event));
    return _callEventsStream!;
  }

  /// 初始化 SDK
  /// 
  /// [config] 配置信息，包含 appKey 等
  static Future<void> init(CallConfig config) async {
    await _methodChannel.invokeMethod('init', config.toMap());
  }

  /// 登录
  ///
  /// [userId] 用户 ID
  /// [token] 登录令牌
  static Future<void> login(String userId, String token) async {
    await _methodChannel.invokeMethod('login', {
      'userId': userId,
      'token': token,
    });
  }

  /// 登出
  static Future<void> logout() async {
    await _methodChannel.invokeMethod('logout');
  }

  /// 发起通话
  ///
  /// [calleeId] 被叫用户 ID
  /// [type] 通话类型（音频/视频）
  /// [ext] 扩展信息
  static Future<void> startCall(
    String calleeId,
    CallType type, {
    Map<String, dynamic>? ext,
  }) async {
    await _methodChannel.invokeMethod('startCall', {
      'calleeId': calleeId,
      'callType': type.value,
      'ext': ext,
    });
  }

  /// 发起音频通话
  static Future<void> startAudioCall(String calleeId, {Map<String, dynamic>? ext}) {
    return startCall(calleeId, CallType.audio, ext: ext);
  }

  /// 发起视频通话
  static Future<void> startVideoCall(String calleeId, {Map<String, dynamic>? ext}) {
    return startCall(calleeId, CallType.video, ext: ext);
  }

  /// 接听通话
  ///
  /// [callId] 通话 ID
  static Future<void> answerCall(String callId) async {
    await _methodChannel.invokeMethod('answerCall', {'callId': callId});
  }

  /// 拒绝通话
  ///
  /// [callId] 通话 ID
  /// [reason] 拒绝原因
  static Future<void> rejectCall(String callId, {String? reason}) async {
    await _methodChannel.invokeMethod('rejectCall', {
      'callId': callId,
      'reason': reason,
    });
  }

  /// 结束通话
  ///
  /// [callId] 通话 ID
  static Future<void> endCall(String callId) async {
    await _methodChannel.invokeMethod('endCall', {'callId': callId});
  }

  /// 切换摄像头
  static Future<void> switchCamera() async {
    await _methodChannel.invokeMethod('switchCamera');
  }

  /// 开启/关闭摄像头
  ///
  /// [enable] true 开启，false 关闭
  static Future<void> enableVideo(bool enable) async {
    await _methodChannel.invokeMethod('enableVideo', {'enable': enable});
  }

  /// 开启/关闭麦克风
  ///
  /// [enable] true 开启，false 关闭
  static Future<void> enableAudio(bool enable) async {
    await _methodChannel.invokeMethod('enableAudio', {'enable': enable});
  }

  /// 开启/关闭扬声器
  ///
  /// [enable] true 开启，false 关闭
  static Future<void> enableSpeaker(bool enable) async {
    await _methodChannel.invokeMethod('enableSpeaker', {'enable': enable});
  }

  /// 获取当前通话状态
  static Future<CallState> getCurrentCallState() async {
    final result = await _methodChannel.invokeMethod<int>('getCurrentCallState');
    return CallState.fromValue(result ?? 0);
  }
}
