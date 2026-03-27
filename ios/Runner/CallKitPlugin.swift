import Flutter
import UIKit
import EaseCallUIKit
import HyphenateChat
import AgoraRtcKit

@objc public class CallKitPlugin: NSObject {
    static let METHOD_CHANNEL = "easemob_flutter_callkit"
    static let EVENT_CHANNEL = "easemob_flutter_callkit/events"
    
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = CallKitPlugin()
        plugin.setupChannels(registrar: registrar)
    }
    
    private func setupChannels(registrar: FlutterPluginRegistrar) {
        // MethodChannel
        methodChannel = FlutterMethodChannel(
            name: CallKitPlugin.METHOD_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        methodChannel?.setMethodCallHandler(handleMethodCall)
        
        // EventChannel
        eventChannel = FlutterEventChannel(
            name: CallKitPlugin.EVENT_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        eventChannel?.setStreamHandler(self)
    }
    
    // MARK: - Method Handlers
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            handleInit(call, result: result)
        case "login":
            handleLogin(call, result: result)
        case "logout":
            handleLogout(result: result)
        case "startCall":
            handleStartCall(call, result: result)
        case "answerCall":
            handleAnswerCall(call, result: result)
        case "rejectCall":
            handleRejectCall(call, result: result)
        case "endCall":
            handleEndCall(call, result: result)
        case "switchCamera":
            handleSwitchCamera(result: result)
        case "enableVideo":
            handleEnableVideo(call, result: result)
        case "enableAudio":
            handleEnableAudio(call, result: result)
        case "enableSpeaker":
            handleEnableSpeaker(call, result: result)
        case "getCurrentCallState":
            handleGetCurrentCallState(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleInit(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let appKey = args["appKey"] as? String else {
            result(FlutterError(code: "INVALID_PARAMS", message: "appKey is required", details: nil))
            return
        }
        
        let enableLog = args["enableLog"] as? Bool ?? false
        
        // 初始化 CallKitManager
        let config = CallKitConfig()
        CallKitManager.shared.setup(config)
        
        // 添加监听器
        CallKitManager.shared.addListener(self)
        
        result(nil)
    }
    
    private func handleLogin(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userId = args["userId"] as? String,
              let token = args["token"] as? String else {
            result(FlutterError(code: "INVALID_PARAMS", message: "userId and token are required", details: nil))
            return
        }
        
        // 【注意】IM SDK 初始化检查已移至 Flutter 层
        // 如需检查，取消下面注释：
        // if EMClient.shared().options == nil {
        //     result(FlutterError(code: "IM_NOT_INITIALIZED", 
        //         message: "环信 IM SDK 未初始化", details: nil))
        //     return
        // }
        
        // 使用环信 IM SDK 账号密码登录（异步方法）
        EMClient.shared().login(withUsername: userId, password: token) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("IM 登录失败: code=\(error.code), desc=\(error.errorDescription ?? "")")
                    result(FlutterError(code: "LOGIN_FAILED", 
                        message: "登录失败: \(error.errorDescription ?? "未知错误")", 
                        details: ["code": error.code]))
                } else {
                    print("IM 登录成功: \(userId)")
                    // 设置当前用户信息
                    let profile = CallUserProfile()
                    profile.id = userId
                    CallKitManager.shared.currentUserInfo = profile
                    
                    result([
                        "success": true,
                        "userId": userId
                    ])
                }
            }
        }
    }
    
    private func handleLogout(result: @escaping FlutterResult) {
        // 使用同步登出方法
        let error = EMClient.shared().logout(true)
        
        if let error = error {
            print("IM 登出失败: \(error)")
        } else {
            print("IM 登出成功")
        }
        
        // 清理 CallKit 资源
        CallKitManager.shared.tearDown()
        CallKitManager.shared.cleanUserDefaults()
        
        result([
            "success": error == nil
        ])
    }
    
    private func handleStartCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let calleeId = args["calleeId"] as? String else {
            result(FlutterError(code: "INVALID_PARAMS", message: "calleeId is required", details: nil))
            return
        }
        
        let callTypeValue = args["callType"] as? Int ?? 0
        let ext = args["ext"] as? [String: Any]
        
        // 转换通话类型: 0-音频, 1-视频
        let type: CallType = (callTypeValue == 1) ? .singleVideo : .singleAudio
        
        // 发起通话
        CallKitManager.shared.call(with: calleeId, type: type, extensionInfo: ext)
        
        result(nil)
    }
    
    private func handleAnswerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // CallKit 内部自动处理接听逻辑
        sendEvent(type: "onCallAccepted", data: ["callId": ""])
        result(nil)
    }
    
    private func handleRejectCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 挂断/拒绝通话
        CallKitManager.shared.hangup()
        sendEvent(type: "onCallRejected", data: ["callId": "", "reason": ""])
        result(nil)
    }
    
    private func handleEndCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        CallKitManager.shared.hangup()
        sendEvent(type: "onCallEnded", data: ["callId": ""])
        result(nil)
    }
    
    private func handleSwitchCamera(result: @escaping FlutterResult) {
        // 切换摄像头 - 内部方法无法直接访问
        // 这些功能在 CallKit UI 中自动处理
        result(nil)
    }
    
    private func handleEnableVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enable = args["enable"] as? Bool else {
            result(nil)
            return
        }
        
        // 开启/关闭摄像头 - 内部方法无法直接访问
        // 这些功能在 CallKit UI 中自动处理
        result(nil)
    }
    
    private func handleEnableAudio(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enable = args["enable"] as? Bool else {
            result(nil)
            return
        }
        
        // 开启/关闭麦克风 - 内部方法无法直接访问
        // 这些功能在 CallKit UI 中自动处理
        result(nil)
    }
    
    private func handleEnableSpeaker(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enable = args["enable"] as? Bool else {
            result(nil)
            return
        }
        
        // 开启/关闭扬声器 - 内部方法无法直接访问
        // 这些功能在 CallKit UI 中自动处理
        result(nil)
    }
    
    private func handleGetCurrentCallState(result: @escaping FlutterResult) {
        // 获取当前通话状态
        // 返回 0 表示空闲状态
        result(0)
    }
    
    // MARK: - Event Helpers
    
    public func sendEvent(type: String, data: [String: Any]?) {
        eventSink?([
            "type": type,
            "data": data ?? [:]
        ])
    }
}

// MARK: - FlutterStreamHandler

extension CallKitPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - CallServiceListener

extension CallKitPlugin: CallServiceListener {
    
    public func didOccurError(error: CallError) {
        sendEvent(type: "onCallError", data: [
            "code": 0,
            "message": ""
        ])
    }
    
    public func remoteUserDidJoined(userId: String, channelName: String, type: CallType) {
        sendEvent(type: "onRemoteUserJoined", data: [
            "userId": userId,
            "channelName": channelName,
            "callType": type.rawValue
        ])
    }
    
    public func remoteUserDidLeft(userId: String, channelName: String, type: CallType) {
        sendEvent(type: "onRemoteUserLeft", data: [
            "userId": userId,
            "channelName": channelName,
            "callType": type.rawValue
        ])
    }
    
    public func didUpdateCallEndReason(reason: CallEndReason, info: CallInfo) {
        sendEvent(type: "onCallEnded", data: [
            "reason": reason.rawValue,
            "callId": info.callId ?? ""
        ])
    }
    
    public func onRtcEngineCreated(engine: AgoraRtcEngineKit) {
        sendEvent(type: "onRtcEngineCreated", data: nil)
    }
    
    public func onReceivedCall(callType: CallType, userId: String, extensionInfo: [String: Any]?) {
        sendEvent(type: "onCallReceived", data: [
            "callType": callType.rawValue,
            "callerId": userId,
            "ext": extensionInfo ?? [:]
        ])
    }
}


