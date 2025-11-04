/// Control Bus 二层协议解码器
///
/// 功能描述：
/// - 将一层负载（payload）解码为 ControlBusMessage（不依赖一层 InterChipPacket）
/// - 由调用方负责选择正确的解码器（Cmd=0xF8 时应选择 ControlBusDecoder），本解码器只关注负载结构
///
/// 使用方式：
/// - 先使用 InterChipDecoder 获取 InterChipPacket
/// - 将 InterChipPacket.payload 传入 ControlBusDecoder.decode(payload) 得到二层结构
library;

import '../../../models/layer2/control_bus_models.dart';
import '../../../interfaces/layer2/layer2_payload_decoder.dart';

/// Control Bus 解码器实现
class ControlBusDecoder implements Layer2PayloadDecoder<ControlBusMessage> {
  /// 解码为 ControlBusMessage（仅基于二层负载）
  ///
  /// 参数：
  /// - payload：Inter-chip 的 payload 字节数组（格式：CbCmd | CbPayload）
  ///
  /// 返回值：
  /// - ControlBusMessage；若负载不合法返回 null
  @override
  ControlBusMessage? decode(List<int> payload) {
    if (payload.isEmpty) {
      return null;
    }
    return ControlBusMessage.fromBytes(payload);
  }
}
