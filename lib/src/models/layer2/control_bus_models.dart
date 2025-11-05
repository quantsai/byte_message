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

  // 注意：过去版本提供了 fromPacket(InterChipPacket) 以支持从一层数据包直接解码；
  // 为避免语义耦合并强化层次边界，该方法已移除，推荐使用 fromBytes(List<int>)。

  /// 从二层字节序列转换为 ControlBusMessage（不依赖一层数据包）
  ///
  /// 参数：
  /// - bytes：格式为 CbCmd | CbPayload
  ///
  /// 返回值：
  /// - ControlBusMessage；若字节序列不合法返回 null
  static ControlBusMessage? fromBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }
    final cbCmd = bytes[0];
    final cbPayload = bytes.length > 1 ? bytes.sublist(1) : <int>[];
    return ControlBusMessage(cbCmd: cbCmd, cbPayload: cbPayload);
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
