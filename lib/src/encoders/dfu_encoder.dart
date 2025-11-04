/// DFU 二层协议编码器
///
/// 功能描述：
/// - 仅编码二层内容（DfuCmd + DfuVersion + DfuPayload）为字节数组
/// - 不加入任何 Inter-chip 一层字段（Flag/Len/LenH/Checksum/Cmd）
/// - 若需要输出最终字节流：请自行构造 InterChipPacket 并使用 InterChipEncoder.encode()
library;

import '../models/dfu_models.dart';

/// DFU 编码器实现
class DfuEncoder {
  /// 编码二层负载为字节数组
  ///
  /// 参数：
  /// - message：DfuMessage（包含 DfuCmd、DfuVersion 与 DfuPayload）
  ///
  /// 返回值：
  /// - List<int>：仅包含二层内容 [dfuCmd, dfuVersion] + dfuPayload，不含任何一层字段
  List<int> encode(DfuMessage message) {
    return <int>[message.dfuCmd, message.dfuVersion, ...message.dfuPayload];
  }
}