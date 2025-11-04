/// Layer2 二层负载编码器抽象接口
///
/// 功能描述：
/// - 定义将二层消息模型编码为字节序列的统一接口
/// - 不涉及任何一层（Layer1）字段的处理（Flag/Len/LenH/Cmd/Checksum）
library;

/// 二层负载编码器抽象类（范型）
///
/// 类型参数：
/// - T：二层消息模型类型（例如 ControlBusMessage、DfuMessage）
abstract class Layer2PayloadEncoder<T> {
  /// 将二层消息模型编码为字节序列
  ///
  /// 参数：
  /// - message：二层消息模型实例
  ///
  /// 返回值：
  /// - List<int>：仅包含二层内容的字节序列，不含任何一层字段
  List<int> encode(T message);
}
