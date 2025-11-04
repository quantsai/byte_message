/// Layer1 通用数据包解码器抽象接口
library byte_message.layer1_packet_decoder;

/// 第一层（Layer1）数据包解码器抽象接口（通用）
///
/// 说明：
/// - 采用泛型参数以避免与具体协议模型绑定
/// - P 表示第一层数据包模型类型（例如某协议的 Packet 类型）
abstract class Layer1PacketDecoder<P> {
  /// 将字节序列解码为包模型 P
  ///
  /// [data] 要解码的二进制数据
  /// 返回解码后的数据包对象，如果解码失败返回null
  ///
  /// 抛出异常：
  /// - 当解码过程中出现错误时应抛出解码器异常（实现类可自定义具体异常类型，如 DecoderException）
  P? decode(List<int> data);

  /// 验证数据的校验和
  ///
  /// [data] 原始数据（不包含校验和字段）
  /// [checksum] 期望的校验和值
  /// 返回true如果校验和匹配
  ///
  /// 抛出异常：
  /// - [ArgumentError] 当参数无效时
  bool verifyChecksum(List<int> data, int checksum);

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
}
