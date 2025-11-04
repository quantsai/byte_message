/// Layer2 二层负载解码器抽象接口
///
/// 功能描述：
/// - 定义将字节序列解码为二层消息模型的统一接口
/// - 不涉及任何一层（Layer1）字段的处理（Flag/Len/LenH/Cmd/Checksum）
library;

/// 二层负载解码器抽象类（范型）
///
/// 类型参数：
/// - T：二层消息模型类型（例如 ControlBusMessage、DfuMessage）
abstract class Layer2PayloadDecoder<T> {
  /// 将二层负载字节序列解码为消息模型
  ///
  /// 参数：
  /// - bytes：仅包含二层内容的字节序列
  ///
  /// 返回值：
  /// - T?：解码成功返回具体消息模型；若字节序列不合法返回 null
  T? decode(List<int> bytes);
}
