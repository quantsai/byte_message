/// Control Bus 二层协议数据模型
///
/// 功能描述：
/// - 封装二层协议中的 CbCmd 与 CbPayload 字段
/// - 提供与一层 InterChipPacket 的互转方法，方便统一编码/解码
///
/// 字段说明：
/// - cbCmd：Control Bus 子命令（u8）
/// - cbPayload：Control Bus 负载数据（字节数组）
///
/// 典型格式（见 byte_message.md#L110）：
/// |Flag|Len|Cmd|_CbCmd_|_CbPayload_|Checksum|
library;

import '../models/packet_models.dart';
import '../models/packet_command.dart';
import '../constants/packet_constants.dart';

/// Control Bus 二层消息
class ControlBusMessage {
  /// 子命令（u8）
  final int cbCmd;

  /// 子负载（字节数组）
  final List<int> cbPayload;

  /// 构造函数
  ///
  /// 参数：
  /// - cbCmd：Control Bus 子命令（0-255）
  /// - cbPayload：Control Bus 负载数据
  const ControlBusMessage({required this.cbCmd, List<int>? cbPayload})
      : cbPayload = cbPayload ?? const [];

  /// 从一层数据包转换为 ControlBusMessage
  ///
  /// 参数：
  /// - packet：InterChipPacket（Cmd 应为 0xF8 / PacketCommand.normal）
  ///
  /// 返回值：
  /// - ControlBusMessage；若格式不合法返回 null
  static ControlBusMessage? fromPacket(InterChipPacket packet) {
    if (packet.cmd.value != PacketConstants.CMD_CONTROL_BUS) {
      return null;
    }
    if (packet.payload.isEmpty) {
      return null;
    }
    final cbCmd = packet.payload[0];
    final cbPayload =
        packet.payload.length > 1 ? packet.payload.sublist(1) : <int>[];
    return ControlBusMessage(cbCmd: cbCmd, cbPayload: cbPayload);
  }

  /// 转换为一层数据包（用于编码前置）
  ///
  /// 设计原则：
  /// - 二层仅生成自身字段（CbCmd、CbPayload），不暴露或携带任何一层字段
  /// - 一层字段（Flag/Len/LenH/Checksum）由 InterChipEncoder 在序列化阶段自动生成
  ///
  /// 返回值：
  /// - InterChipPacket：Cmd 固定为 PacketCommand.normal（0xF8），payload 为 [cbCmd] + cbPayload
  InterChipPacket toPacket() {
    final payload = <int>[cbCmd, ...cbPayload];
    return InterChipPacket(
      cmd: PacketCommand.normal,
      payload: payload,
    );
  }

  @override
  String toString() =>
      'ControlBusMessage{cbCmd: 0x${cbCmd.toRadixString(16).padLeft(2, '0')}, cbPayload: $cbPayload}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ControlBusMessage) return false;
    if (cbCmd != other.cbCmd) return false;
    if (cbPayload.length != other.cbPayload.length) return false;
    for (int i = 0; i < cbPayload.length; i++) {
      if (cbPayload[i] != other.cbPayload[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(cbCmd, Object.hashAll(cbPayload));
}