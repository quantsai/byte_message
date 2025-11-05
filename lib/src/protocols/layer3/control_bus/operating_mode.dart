/// 控制总线第三层协议：功能模式（Operating Mode）
///
/// 文档参考：control.md#L147-167
/// - 请求：指令编号 0x3D，第三层请求负载为空（无数据）。
/// - 应答：功能模式 u8（0x00 手动模式，0x01 自平衡模式）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.operating_mode;

/// 第三层：功能模式请求
class OperatingModeReq {
  /// 编码第三层请求负载
  ///
  /// 功能：功能模式请求在第三层无负载，返回空数组。
  /// 参数：无
  /// 返回：List<int> 空数组 []
  List<int> encode() {
    return const <int>[];
  }
}

/// 第三层：功能模式应答
class OperatingModeRes {
  /// 功能模式（u8）
  /// 0x00 手动模式；0x01 自平衡模式（参见 control.md 定义）。
  final OperatingMode mode;

  /// 构造函数
  ///
  /// 参数：
  /// - mode：功能模式（u8，0..255）。
  OperatingModeRes({required this.mode});

  /// 从第三层字节数组解析功能模式应答
  ///
  /// 功能：解析长度为 1 的载荷，返回 OperatingModeRes。
  /// 参数：
  /// - bytes：第三层载荷，必须仅包含 1 字节（u8 功能模式）。
  /// 返回：OperatingModeRes
  /// 异常：
  /// - ArgumentError：当载荷长度不是 1 时抛出。
  static OperatingModeRes fromBytes(List<int> bytes) {
    if (bytes.length != 1) {
      throw ArgumentError(
        'Invalid L3 operating mode payload length: expected 1, got ${bytes.length}',
      );
    }
    final modeByte = bytes[0] & 0xFF; // u8
    final mode = OperatingMode.fromValue(modeByte);
    return OperatingModeRes(mode: mode);
  }

  @override
  String toString() => 'OperatingModeRes{mode: $mode}';
}

enum OperatingMode {
  /// 手动模式
  manual(0x00),

  /// 自平衡模式
  selfBalance(0x01);

  /// 模式值（u8）
  final int value;

  /// 构造函数
  const OperatingMode(this.value);

  /// 从值创建枚举实例
  factory OperatingMode.fromValue(int value) {
    return OperatingMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid operating mode value: $value'),
    );
  }
}
