/// Inter-chip 协议命令枚举
/// 
/// 定义了 inter-chip 协议中 Cmd 字段的所有可用命令类型
library;

/// 数据包命令枚举
/// 
/// 包含了 inter-chip 协议中定义的所有命令类型：
/// - [normal]: 普通指令 (0xF8) - 用于常规通信
/// - [dfu]: DFU指令 (0x20) - 用于设备固件升级过程
enum PacketCommand {
  /// 普通指令 (0xF8)
  /// 
  /// 使用 inter-chip 通讯协议的扩展模式，用于常规设备间通信
  normal(0xF8),
  
  /// DFU指令 (0x20)
  /// 
  /// 在设备 DFU 时使用，用于开启和结束升级过程，以及接受升级数据
  dfu(0x20);

  /// 构造函数
  /// 
  /// [value] 命令的字节值
  const PacketCommand(this.value);

  /// 命令的字节值
  final int value;

  /// 从字节值创建命令枚举
  /// 
  /// [value] 要转换的字节值
  /// 
  /// 返回对应的 [PacketCommand] 枚举值
  /// 
  /// 抛出 [ArgumentError] 如果字节值不对应任何已知命令
  static PacketCommand fromValue(int value) {
    for (final command in PacketCommand.values) {
      if (command.value == value) {
        return command;
      }
    }
    throw ArgumentError('Unknown command value: 0x${value.toRadixString(16)}');
  }

  /// 检查字节值是否为有效的命令
  /// 
  /// [value] 要检查的字节值
  /// 
  /// 返回 true 如果是有效命令，否则返回 false
  static bool isValidCommand(int value) {
    return PacketCommand.values.any((command) => command.value == value);
  }

  /// 获取所有可用命令的字节值列表
  /// 
  /// 返回包含所有命令字节值的列表
  static List<int> get allValues => PacketCommand.values.map((cmd) => cmd.value).toList();

  @override
  String toString() {
    switch (this) {
      case PacketCommand.normal:
        return 'PacketCommand.normal(0x${value.toRadixString(16)})';
      case PacketCommand.dfu:
        return 'PacketCommand.dfu(0x${value.toRadixString(16)})';
    }
  }
}