/// DFU 二层协议解码器
///
/// 功能描述：
/// - 将一层 InterChipPacket 解码为 DfuMessage
/// - 验证 Cmd 类型是否为 DFU（0x20）
///
/// 使用方式：
/// - 先使用 InterChipDecoder 获取 InterChipPacket
/// - 再调用 DfuDecoder.decode(packet) 得到二层结构
library;

import '../models/packet_models.dart';
import '../models/dfu_models.dart';
import '../constants/packet_constants.dart';

/// DFU 解码器实现
class DfuDecoder {
  /// 解码为 DfuMessage
  ///
  /// 参数：
  /// - packet：已通过一层校验的 InterChipPacket
  ///
  /// 返回值：
  /// - DfuMessage；若 Cmd 不匹配或负载不合法，返回 null
  DfuMessage? decode(InterChipPacket packet) {
    if (packet.cmd.value != PacketConstants.CMD_DFU) {
      return null;
    }
    return DfuMessage.fromPacket(packet);
  }
}