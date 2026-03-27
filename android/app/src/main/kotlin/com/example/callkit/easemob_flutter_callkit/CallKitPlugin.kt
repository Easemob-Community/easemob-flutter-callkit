package com.example.callkit.easemob_flutter_callkit

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.hyphenate.EMCallBack
import com.hyphenate.callkit.CallKitClient
import com.hyphenate.callkit.CallKitConfig
import com.hyphenate.callkit.bean.CallEndReason
import com.hyphenate.callkit.bean.CallInfo
import com.hyphenate.callkit.bean.CallType
import com.hyphenate.callkit.interfaces.CallKitListener
import com.hyphenate.chat.EMClient
import io.agora.rtc2.RtcEngine
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

/**
 * CallKit MethodChannel 插件
 */
class CallKitPlugin : MethodCallHandler, EventChannel.StreamHandler, CallKitListener {
    
    companion object {
        private const val TAG = "CallKitPlugin"
        const val METHOD_CHANNEL = "easemob_flutter_callkit"
        const val EVENT_CHANNEL = "easemob_flutter_callkit/events"
        
        @JvmStatic
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val plugin = CallKitPlugin()
            
            // 初始化 Context
            plugin.initContext(context)
            
            // 注册 MethodChannel
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                .setMethodCallHandler(plugin)
            
            // 注册 EventChannel
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(plugin)
        }
    }
    
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    
    fun initContext(context: Context) {
        this.context = context
        // 设置 CallKit 监听器
        CallKitClient.callKitListener = this
    }
    
    //region CallKitListener
    
    override fun onEndCallWithReason(reason: CallEndReason, callInfo: CallInfo?) {
        sendEvent("onCallEnded", mapOf(
            "reason" to reason.ordinal,
            "callId" to (callInfo?.callId ?: "")
        ))
    }
    
    override fun onCallError(errorType: CallKitClient.CallErrorType, errorCode: Int, description: String?) {
        sendEvent("onCallError", mapOf(
            "errorType" to errorType.ordinal,
            "errorCode" to errorCode,
            "description" to (description ?: "")
        ))
    }
    
    override fun onReceivedCall(userId: String, callType: CallType, ext: JSONObject?) {
        val extMap = mutableMapOf<String, Any>()
        ext?.keys()?.forEach { key ->
            extMap[key] = ext.opt(key) ?: ""
        }
        sendEvent("onCallReceived", mapOf(
            "callerId" to userId,
            "callType" to if (callType == CallType.SINGLE_VIDEO_CALL) 1 else 0,
            "ext" to extMap
        ))
    }
    
    override fun onRemoteUserJoined(userId: String, callType: CallType, channelName: String) {
        sendEvent("onRemoteUserJoined", mapOf(
            "userId" to userId,
            "callType" to if (callType == CallType.SINGLE_VIDEO_CALL) 1 else 0,
            "channelName" to channelName
        ))
    }
    
    override fun onRemoteUserLeft(userId: String, callType: CallType, channelName: String) {
        sendEvent("onRemoteUserLeft", mapOf(
            "userId" to userId,
            "callType" to if (callType == CallType.SINGLE_VIDEO_CALL) 1 else 0,
            "channelName" to channelName
        ))
    }
    
    override fun onRtcEngineCreated(engine: RtcEngine) {
        sendEvent("onRtcEngineCreated", null)
    }
    
    //endregion
    
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "init" -> handleInit(call, result)
            "login" -> handleLogin(call, result)
            "logout" -> handleLogout(result)
            "startCall" -> handleStartCall(call, result)
            "answerCall" -> handleAnswerCall(call, result)
            "rejectCall" -> handleRejectCall(call, result)
            "endCall" -> handleEndCall(call, result)
            "switchCamera" -> handleSwitchCamera(result)
            "enableVideo" -> handleEnableVideo(call, result)
            "enableAudio" -> handleEnableAudio(call, result)
            "enableSpeaker" -> handleEnableSpeaker(call, result)
            "getCurrentCallState" -> handleGetCurrentCallState(result)
            else -> result.notImplemented()
        }
    }
    
    //region Method Handlers
    
    private fun handleInit(call: MethodCall, result: Result) {
        val appKey = call.argument<String>("appKey")
        val enableLog = call.argument<Boolean>("enableLog") ?: false
        
        context?.let { ctx ->
            // 【注意】IM SDK 初始化已移至 Flutter 层
            // 如需检查 IM SDK 是否初始化，取消下面注释：
            // if (!EMClient.getInstance().isSdkInited) {
            //     result.error("IM_NOT_INITIALIZED", 
            //         "环信 IM SDK 未初始化", null)
            //     return
            // }
            
            val config = CallKitConfig().apply {
                // 配置 CallKit
            }
            val success = CallKitClient.init(ctx, config)
            result.success(success)
        } ?: run {
            result.error("NO_CONTEXT", "Context is null", null)
        }
    }
    
    private fun handleLogin(call: MethodCall, result: Result) {
        val userId = call.argument<String>("userId")
        val password = call.argument<String>("token")  // 使用 password 参数
        
        if (userId == null || password == null) {
            result.error("INVALID_PARAMS", "userId or password is null", null)
            return
        }
        
        // 【注意】IM SDK 初始化检查已移至 Flutter 层
        // 如需检查，取消下面注释：
        // if (!EMClient.getInstance().isSdkInited) {
        //     result.error("IM_NOT_INITIALIZED", 
        //         "环信 IM SDK 未初始化", null)
        //     return
        // }
        
        // 使用环信 IM SDK 账号密码登录
        EMClient.getInstance().login(userId, password, object : EMCallBack {
            override fun onSuccess() {
                Log.i(TAG, "IM 登录成功: $userId")
                mainHandler.post {
                    result.success(mapOf(
                        "success" to true,
                        "userId" to userId
                    ))
                }
            }
            
            override fun onError(code: Int, error: String?) {
                Log.e(TAG, "IM 登录失败: code=$code, error=$error")
                mainHandler.post {
                    result.error("LOGIN_FAILED", "登录失败: $error", mapOf(
                        "code" to code,
                        "error" to error
                    ))
                }
            }
            
            override fun onProgress(progress: Int, status: String?) {
                // 登录进度回调，可选处理
            }
        })
    }
    
    private fun handleLogout(result: Result) {
        // 登出环信 IM SDK
        EMClient.getInstance().logout(true, object : EMCallBack {
            override fun onSuccess() {
                Log.i(TAG, "IM 登出成功")
                // 清理 CallKit 资源
                CallKitClient.cleanUp()
                mainHandler.post {
                    result.success(mapOf("success" to true))
                }
            }
            
            override fun onError(code: Int, error: String?) {
                Log.e(TAG, "IM 登出失败: code=$code, error=$error")
                // 即使登出失败也清理 CallKit 资源
                CallKitClient.cleanUp()
                mainHandler.post {
                    result.error("LOGOUT_FAILED", "登出失败: $error", null)
                }
            }
            
            override fun onProgress(progress: Int, status: String?) {}
        })
    }
    
    private fun handleStartCall(call: MethodCall, result: Result) {
        val calleeId = call.argument<String>("calleeId")
        val callTypeValue = call.argument<Int>("callType") ?: 0
        val ext = call.argument<Map<String, Any>>("ext")
        
        if (calleeId == null) {
            result.error("INVALID_PARAMS", "calleeId is null", null)
            return
        }
        
        val type = if (callTypeValue == 1) CallType.SINGLE_VIDEO_CALL else CallType.SINGLE_VOICE_CALL
        val extJson = ext?.let { JSONObject(it) }
        
        CallKitClient.startSingleCall(type, calleeId, extJson)
        result.success(null)
    }
    
    private fun handleAnswerCall(call: MethodCall, result: Result) {
        val callId = call.argument<String>("callId")
        
        // CallKit 内部自动处理接听逻辑，这里发送事件通知
        sendEvent("onCallAccepted", mapOf("callId" to (callId ?: "")))
        
        result.success(null)
    }
    
    private fun handleRejectCall(call: MethodCall, result: Result) {
        val callId = call.argument<String>("callId")
        val reason = call.argument<String>("reason")
        
        // 结束通话（拒绝）
        CallKitClient.endCall()
        sendEvent("onCallRejected", mapOf("callId" to (callId ?: ""), "reason" to (reason ?: "")))
        
        result.success(null)
    }
    
    private fun handleEndCall(call: MethodCall, result: Result) {
        val callId = call.argument<String>("callId")
        
        CallKitClient.endCall()
        sendEvent("onCallEnded", mapOf("callId" to (callId ?: "")))
        
        result.success(null)
    }
    
    private fun handleSwitchCamera(result: Result) {
        // 注意：CallKitClient.rtcManager 是 internal 的，无法直接访问
        // 这些功能在 CallKit UI 中自动处理
        // 如需在 Flutter 层控制，需要扩展原生 SDK
        result.success(null)
    }
    
    private fun handleEnableVideo(call: MethodCall, result: Result) {
        val enable = call.argument<Boolean>("enable") ?: true
        
        // 注意：CallKitClient.rtcManager 是 internal 的，无法直接访问
        // 视频控制在 CallKit UI 中自动处理
        result.success(null)
    }
    
    private fun handleEnableAudio(call: MethodCall, result: Result) {
        val enable = call.argument<Boolean>("enable") ?: true
        
        // 注意：CallKitClient.rtcManager 是 internal 的，无法直接访问
        // 音频控制在 CallKit UI 中自动处理
        result.success(null)
    }
    
    private fun handleEnableSpeaker(call: MethodCall, result: Result) {
        val enable = call.argument<Boolean>("enable") ?: true
        
        // 注意：CallKitClient.rtcManager 是 internal 的，无法直接访问
        // 扬声器控制在 CallKit UI 中自动处理
        result.success(null)
    }
    
    private fun handleGetCurrentCallState(result: Result) {
        // 注意：CallKitClient.callState 是 internal 的
        // 返回 0 表示空闲状态
        result.success(0)
    }
    
    //endregion
    
    //region EventChannel
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }
    
    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
    
    /**
     * 发送事件到 Flutter（确保在主线程执行）
     */
    fun sendEvent(type: String, data: Map<String, Any>?) {
        mainHandler.post {
            eventSink?.success(mapOf(
                "type" to type,
                "data" to data
            ))
        }
    }
    
    //endregion
}
