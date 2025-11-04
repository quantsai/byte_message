/// Control Bus 二层协议解码器
///
/// 功能描述：
/// - 将一层 InterChipPacket 解码为 ControlBusMessage
/// - 验证 Cmd 类型是否为 Control Bus（0xF8）
///
/// 使用方式：
/// - 先使用 InterChipDecoder 获取 InterChipPacket
/// - 再调用 ControlBusDecoder.decode(packet) 得到二层结构
library;

import '../models/packet_models.dart';
import '../models/control_bus_models.dart';
import '../constants/packet_constants.dart';

/// Control Bus 解码器实现
class ControlBusDecoder {
  /// 解码为 ControlBusMessage
  ///
  /// 参数：
  /// - packet：已通过一层校验的 InterChipPacket
  ///
  /// 返回值：
  /// - ControlBusMessage；若 Cmd 不匹配或负载不合法，返回 null
  ControlBusMessage? decode(InterChipPacket packet) {
    if (packet.cmd.value != PacketConstants.CMD_CONTROL_BUS) {
      return null;
    }
    return ControlBusMessage.fromPacket(packet);
  }
}