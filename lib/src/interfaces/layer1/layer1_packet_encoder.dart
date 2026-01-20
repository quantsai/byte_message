/// Layer1 通用数据包编码器抽象接口
library byte_message.layer1_packet_encoder;

/// 第一层（Layer1）数据包编码器抽象接口（通用）
///
/// 说明：
/// - 采用泛型参数以避免与具体协议模型绑定
/// - P 表示第一层数据包模型类型（例如某协议的 Packet 类型）
abstract class Layer1PacketEncoder<P> {
  /// 将包模型 P 编码为字节序列
  ///
  /// [packet] 要编码的包模型对象
  /// 返回编码后的字节序列（List<int>）
  ///
  /// 抛出异常：
  /// - [ArgumentError] 当输入包模型参数无效时
  /// - [StateError] 当编码过程中出现状态错误时
  List<int> encode(P packet);

  /// 计算数据的校验和
  ///
  /// [data] 要计算校验和的数据（不包含校验和字段本身）
  /// 返回计算得到的校验和值
  ///
  /// 抛出异常：
  /// - [ArgumentError] 当数据无效时
  int calculateChecksum(List<int> data);

  /// 验证包模型 P 的有效性
  ///
  /// [packet] 要验证的包模型对象
  ///
  /// 验证内容包括：
  /// - 字段值范围检查
  /// - 长度一致性检查
  /// - 标志位合法性检查
  ///
  /// 抛出异常：
  /// - 当包模型无效时应抛出标准异常（如 ArgumentError/StateError），避免在抽象层引入具体异常类型
  void validatePacket(P packet);

  /// 根据包模型 P 判断是否需要使用长帧模式（如协议支持）
  ///
  /// [packet] 包模型对象
  /// 返回 true 则表示需要长帧模式
  bool requiresLongFrame(P packet);
}

// 注意：抽象层不定义具体异常类型，具体实现应使用标准异常（ArgumentError/StateError/RangeError）
