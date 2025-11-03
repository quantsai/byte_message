/// Inter-chip协议编码器抽象接口
library;

import '../models/packet_models.dart';

/// 数据包编码器抽象接口
///
/// 定义了将InterChipPacket编码为二进制数据的标准接口
abstract class PacketEncoder {
  /// 将InterChipPacket编码为二进制数据
  ///
  /// [packet] 要编码的数据包对象
  /// 返回编码后的二进制数据
  ///
  /// 抛出异常：
  /// - [ArgumentError] 当数据包参数无效时
  /// - [StateError] 当编码过程中出现状态错误时
  List<int> encode(InterChipPacket packet);

  /// 计算数据的校验和
  ///
  /// [data] 要计算校验和的数据（不包含校验和字段本身）
  /// 返回计算得到的校验和值
  ///
  /// 抛出异常：
  /// - [ArgumentError] 当数据无效时
  int calculateChecksum(List<int> data);

  /// 验证数据包的有效性
  ///
  /// [packet] 要验证的数据包对象
  ///
  /// 验证内容包括：
  /// - 字段值范围检查
  /// - 长度一致性检查
  /// - 标志位合法性检查
  ///
  /// 抛出异常：
  /// - [EncoderException] 当数据包无效时
  void validatePacket(InterChipPacket packet);

  /// 根据数据包判断是否需要长帧模式
  ///
  /// [packet] 数据包对象
  /// 返回true如果需要长帧模式
  bool requiresLongFrame(InterChipPacket packet);

  /// 根据数据包内容自动生成合适的PacketFlags
  ///
  /// [packet] 数据包对象
  /// 返回合适的PacketFlags对象
  ///
  /// 自动判断逻辑：
  /// - 根据负载长度决定是否启用长帧模式
  /// - 根据命令类型决定协议类型
  /// - 根据命令判断是否为应答
  PacketFlags generateFlags(InterChipPacket packet);
}

/// 编码器异常类
class EncoderException implements Exception {
  /// 异常消息
  final String message;

  /// 异常代码（可选）
  final String? code;

  /// 原始异常（可选）
  final Object? cause;

  /// 构造函数
  const EncoderException(this.message, {this.code, this.cause});

  @override
  String toString() {
    String result = 'EncoderException: $message';
    if (code != null) result += ' (code: $code)';
    if (cause != null) result += ' (cause: $cause)';
    return result;
  }
}
