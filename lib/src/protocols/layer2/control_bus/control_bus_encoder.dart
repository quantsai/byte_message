/// Control Bus 二层协议编码器
///
/// 功能描述：
/// - 仅编码二层内容（CbCmd + CbPayload）为字节数组
/// - 不加入任何 Inter-chip 一层字段（Flag/Len/LenH/Checksum/Cmd）
/// - 若需要输出最终字节流：请自行构造 InterChipPacket 并使用 InterChipEncoder.encode()
library;

import '../../../models/layer2/control_bus_models.dart';
import '../../../interfaces/layer2/layer2_payload_encoder.dart';

/// Control Bus 编码器实现
class ControlBusEncoder implements Layer2PayloadEncoder<ControlBusMessage> {
  /// 编码二层负载为字节数组
  ///
  /// 参数：
  /// - message：ControlBusMessage（包含 CbCmd 与 CbPayload）
  ///
  /// 返回值：
  /// - List<int>：仅包含二层内容 [cbCmd] + cbPayload，不含任何一层字段
  @override
  List<int> encode(ControlBusMessage message) {
    return <int>[message.cbCmd.code, ...message.cbPayload];
  }
}
