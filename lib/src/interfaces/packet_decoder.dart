/// Inter-chip协议解码器抽象接口
library;

import '../models/packet_models.dart';

/// 数据包解码器抽象接口
/// 
/// 定义了将二进制数据解码为InterChipPacket的标准接口
abstract class PacketDecoder {
  /// 将二进制数据解码为InterChipPacket
  /// 
  /// [data] 要解码的二进制数据
  /// 返回解码后的数据包对象，如果解码失败返回null
  /// 
  /// 抛出异常：
  /// - [DecoderException] 当解码过程中出现错误时
  InterChipPacket? decode(List<int> data);
  
  /// 验证数据的校验和
  /// 
  /// [data] 原始数据（不包含校验和字段）
  /// [checksum] 期望的校验和值
  /// 返回true如果校验和匹配
  /// 
  /// 抛出异常：
  /// - [ArgumentError] 当参数无效时
  bool verifyChecksum(List<int> data, int checksum);
  
  /// 解析Flag字段
  /// 
  /// [flag] Flag字节值
  /// 返回解析后的标志位信息
  /// 
  /// 抛出异常：
  /// - [ArgumentError] 当Flag值无效时
  PacketFlags parseFlags(int flag);
  
  /// 检查数据包的基本格式是否正确
  /// 
  /// [data] 要检查的二进制数据
  /// 返回true如果基本格式正确
  bool isValidPacketFormat(List<int> data);
  
  /// 计算期望的数据包长度
  /// 
  /// [data] 数据包的前几个字节（至少包含Flag和Len）
  /// 返回期望的完整数据包长度，如果无法计算返回null
  int? calculateExpectedLength(List<int> data);
  
  /// 尝试从不完整的数据中解码
  /// 
  /// [data] 可能不完整的数据
  /// 返回解码结果，包含是否需要更多数据的信息
  DecodeResult tryDecode(List<int> data);
}

/// 解码结果类
class DecodeResult {
  /// 解码是否成功
  final bool success;
  
  /// 解码后的数据包（成功时非null）
  final InterChipPacket? packet;
  
  /// 是否需要更多数据
  final bool needMoreData;
  
  /// 已消费的字节数
  final int consumedBytes;
  
  /// 错误信息（失败时提供）
  final String? error;
  
  /// 错误代码（失败时提供）
  final String? errorCode;

  /// 构造函数
  const DecodeResult({
    required this.success,
    this.packet,
    this.needMoreData = false,
    this.consumedBytes = 0,
    this.error,
    this.errorCode,
  });

  /// 创建成功的解码结果
  factory DecodeResult.success(InterChipPacket packet, int consumedBytes) {
    return DecodeResult(
      success: true,
      packet: packet,
      consumedBytes: consumedBytes,
    );
  }

  /// 创建需要更多数据的结果
  factory DecodeResult.needMoreData([String? message]) {
    return DecodeResult(
      success: false,
      needMoreData: true,
      error: message ?? 'Need more data to complete decoding',
    );
  }

  /// 创建失败的解码结果
  factory DecodeResult.failure(String error, {String? errorCode, int consumedBytes = 0}) {
    return DecodeResult(
      success: false,
      error: error,
      errorCode: errorCode,
      consumedBytes: consumedBytes,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'DecodeResult.success(packet: $packet, consumedBytes: $consumedBytes)';
    } else if (needMoreData) {
      return 'DecodeResult.needMoreData(error: $error)';
    } else {
      return 'DecodeResult.failure(error: $error, errorCode: $errorCode, consumedBytes: $consumedBytes)';
    }
  }
}

/// 解码器异常类
class DecoderException implements Exception {
  /// 异常消息
  final String message;
  
  /// 异常代码（可选）
  final String? code;
  
  /// 原始异常（可选）
  final Object? cause;
  
  /// 出错时的数据位置（可选）
  final int? position;

  /// 构造函数
  const DecoderException(this.message, {this.code, this.cause, this.position});

  @override
  String toString() {
    String result = 'DecoderException: $message';
    if (code != null) result += ' (code: $code)';
    if (position != null) result += ' (position: $position)';
    if (cause != null) result += ' (cause: $cause)';
    return result;
  }
}

/// 解码器配置类
class DecoderConfig {
  /// 是否严格验证校验和
  final bool strictChecksumValidation;
  
  /// 是否允许未知的Flag值
  final bool allowUnknownFlags;
  
  /// 是否严格验证长度
  final bool strictLengthValidation;
  
  /// 最大允许的数据包长度
  final int maxPacketLength;
  
  /// 是否启用调试模式
  final bool debugMode;

  /// 构造函数
  const DecoderConfig({
    this.strictChecksumValidation = true,
    this.allowUnknownFlags = false,
    this.strictLengthValidation = true,
    this.maxPacketLength = 65600, // 稍大于最大可能的数据包长度
    this.debugMode = false,
  });

  /// 创建配置的副本
  DecoderConfig copyWith({
    bool? strictChecksumValidation,
    bool? allowUnknownFlags,
    bool? strictLengthValidation,
    int? maxPacketLength,
    bool? debugMode,
  }) {
    return DecoderConfig(
      strictChecksumValidation: strictChecksumValidation ?? this.strictChecksumValidation,
      allowUnknownFlags: allowUnknownFlags ?? this.allowUnknownFlags,
      strictLengthValidation: strictLengthValidation ?? this.strictLengthValidation,
      maxPacketLength: maxPacketLength ?? this.maxPacketLength,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  @override
  String toString() {
    return 'DecoderConfig{'
        'strictChecksumValidation: $strictChecksumValidation, '
        'allowUnknownFlags: $allowUnknownFlags, '
        'strictLengthValidation: $strictLengthValidation, '
        'maxPacketLength: $maxPacketLength, '
        'debugMode: $debugMode'
        '}';
  }
}