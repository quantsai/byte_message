/// DFU 二层协议数据模型
///
/// 功能描述：
/// - 封装 DFU 协议中的 DfuCmd、DfuVersion 与 DfuPayload 字段
/// - 提供与一层 InterChipPacket 的互转方法，方便统一编码/解码
///
/// 字段说明：
/// - dfuCmd：DFU 子命令（u8）
/// - dfuVersion：DFU 协议版本（u8）
/// - dfuPayload：DFU 负载数据（字节数组）
///
/// 典型格式（见 byte_message.md#L181）：
/// |Flag|Len|Cmd|_DfuCmd_|_DfuVersion_|_DfuPayload_|Checksum|
library;

import '../layer1/inter_chip_models.dart';
import '../../constants/packet_constants.dart';

/// DFU 二层消息
class DfuMessage {
  /// 子命令（u8）
  final int dfuCmd;

  /// 协议版本（u8）
  final int dfuVersion;

  /// 负载（字节数组）
  final List<int> dfuPayload;

  /// 构造函数
  ///
  /// 参数：
  /// - dfuCmd：DFU 子命令（0-255）
  /// - dfuVersion：DFU 协议版本（0-255）
  /// - dfuPayload：DFU 负载数据
  const DfuMessage({
    required this.dfuCmd,
    required this.dfuVersion,
    List<int>? dfuPayload,
  }) : dfuPayload = dfuPayload ?? const [];

  /// 从一层数据包转换为 DfuMessage
  ///
  /// 参数：
  /// - packet：InterChipPacket（Cmd 应为 0x20 / InterChipCmds.dfu）
  ///
  /// 返回值：
  /// - DfuMessage；若格式不合法返回 null
  static DfuMessage? fromPacket(InterChipPacket packet) {
    if (packet.cmd.value != PacketConstants.CMD_DFU) {
      return null;
    }
    if (packet.payload.length < 2) {
      return null; // 至少包含 dfuCmd 与 dfuVersion
    }
    final dfuCmd = packet.payload[0];
    final dfuVersion = packet.payload[1];
    final dfuPayload =
        packet.payload.length > 2 ? packet.payload.sublist(2) : <int>[];
    return DfuMessage(
      dfuCmd: dfuCmd,
      dfuVersion: dfuVersion,
      dfuPayload: dfuPayload,
    );
  }

  /// 从二层字节序列转换为 DfuMessage（不依赖一层数据包）
  ///
  /// 参数：
  /// - bytes：格式为 DfuCmd | DfuVersion | DfuPayload
  ///
  /// 返回值：
  /// - DfuMessage；若字节序列不合法返回 null
  static DfuMessage? fromBytes(List<int> bytes) {
    if (bytes.length < 2) {
      return null; // 至少包含 dfuCmd 与 dfuVersion
    }
    final dfuCmd = bytes[0];
    final dfuVersion = bytes[1];
    final dfuPayload = bytes.length > 2 ? bytes.sublist(2) : <int>[];
    return DfuMessage(
      dfuCmd: dfuCmd,
      dfuVersion: dfuVersion,
      dfuPayload: dfuPayload,
    );
  }

  /// 转换为一层数据包（用于编码前置）
  ///
  /// 设计原则：
  /// - 二层仅生成自身字段（DfuCmd、DfuVersion、DfuPayload），不暴露或携带任何一层字段
  /// - 一层字段（Flag/Len/LenH/Checksum）由 InterChipEncoder 在序列化阶段自动生成
  ///
  /// 返回值：
  /// - InterChipPacket：Cmd 固定为 InterChipCmds.dfu（0x20），payload 为 [dfuCmd, dfuVersion] + dfuPayload
  InterChipPacket toPacket() {
    final payload = <int>[dfuCmd, dfuVersion, ...dfuPayload];
    return InterChipPacket(
      cmd: InterChipCmds.dfu,
      payload: payload,
    );
  }

  @override
  String toString() =>
      'DfuMessage{dfuCmd: 0x${dfuCmd.toRadixString(16).padLeft(2, '0')}, dfuVersion: $dfuVersion, dfuPayload: $dfuPayload}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DfuMessage) return false;
    if (dfuCmd != other.dfuCmd || dfuVersion != other.dfuVersion) return false;
    if (dfuPayload.length != other.dfuPayload.length) return false;
    for (int i = 0; i < dfuPayload.length; i++) {
      if (dfuPayload[i] != other.dfuPayload[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(dfuCmd, dfuVersion, Object.hashAll(dfuPayload));
}
