/// DFU 二层协议解码器
///
/// 功能描述：
/// - 将一层负载（payload）解码为 DfuMessage（不依赖一层 InterChipPacket）
/// - 由调用方负责选择正确的解码器（Cmd=0x20 时应选择 DfuDecoder），本解码器只关注负载结构
///
/// 使用方式：
/// - 先使用 InterChipDecoder 获取 InterChipPacket
/// - 将 InterChipPacket.payload 传入 DfuDecoder.decode(payload) 得到二层结构
library;

import '../../../models/layer2/dfu_models.dart';
import '../../../interfaces/layer2/layer2_payload_decoder.dart';

/// DFU 解码器实现
class DfuDecoder implements Layer2PayloadDecoder<DfuMessage> {
  /// 解码为 DfuMessage（仅基于二层负载）
  ///
  /// 参数：
  /// - payload：Inter-chip 的 payload 字节数组（格式：DfuCmd | DfuVersion | DfuPayload）
  ///
  /// 返回值：
  /// - DfuMessage；若负载不合法返回 null
  @override
  DfuMessage? decode(List<int> payload) {
    if (payload.length < 2) {
      return null; // 至少包含 dfuCmd 与 dfuVersion
    }
    return DfuMessage.fromBytes(payload);
  }
}
