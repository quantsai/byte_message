/// Inter-chip协议的核心数据模型定义
library;

import '../../constants/packet_constants.dart';
import '../../utils/packet_utils.dart';

/// Inter-chip 协议命令枚举（合并至本文件，统一管理一层数据结构与命令）
///
/// 定义了 inter-chip 协议中 Cmd 字段的所有可用命令类型：
/// - [normal]: 普通指令 (0xF8) - 用于常规通信
/// - [dfu]: DFU指令 (0x20) - 用于设备固件升级过程
enum InterChipCmds {
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
  const InterChipCmds(this.value);

  /// 命令的字节值
  final int value;

  /// 从字节值创建命令枚举
  ///
  /// [value] 要转换的字节值
  ///
  /// 返回对应的 [InterChipCmds] 枚举值
  ///
  /// 抛出 [ArgumentError] 如果字节值不对应任何已知命令
  static InterChipCmds fromValue(int value) {
    for (final command in InterChipCmds.values) {
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
    return InterChipCmds.values.any((command) => command.value == value);
  }

  /// 获取所有可用命令的字节值列表
  ///
  /// 返回包含所有命令字节值的列表
  static List<int> get allValues =>
      InterChipCmds.values.map((cmd) => cmd.value).toList();

  @override
  String toString() {
    switch (this) {
      case InterChipCmds.normal:
        return 'InterChipCmds.normal(0x${value.toRadixString(16)})';
      case InterChipCmds.dfu:
        return 'InterChipCmds.dfu(0x${value.toRadixString(16)})';
    }
  }
}

/// Inter-chip数据包结构
///
/// 数据包格式：|Flag|Len|LenH|Cmd|Payload|Checksum|
/// - Flag: u8? 标志位，定义数据包的解释方式（可选）
/// - Len: u8? 长度低位，表示Payload+Cmd的长度（可选）
/// - LenH: u8? 长度高位，当LongFrame启用时存在（可选）
/// - Cmd: InterChipCmds 命令字段，表示操作类型
/// - Payload: u8[n] 数据负载
/// - Checksum: u8? 校验和，当ChecksumEnable启用时存在（可选）
class InterChipPacket {
  /// 标志位字段（可选，用户传入时使用，否则为null）
  final int? flag;

  /// 长度字段低位（可选，用户传入时使用，否则为null）
  final int? len;

  /// 长度字段高位（可选，用户传入时使用，否则为null）
  final int? lenH;

  /// 命令字段
  final InterChipCmds cmd;

  /// 数据负载
  final List<int> payload;

  /// 校验和字段（可选，用户传入时使用，否则为null）
  final int? checksum;

  /// 构造函数
  ///
  /// [flag] 标志位，用户传入时使用，否则为null
  /// [len] 长度低位，用户传入时使用，否则为null
  /// [lenH] 长度高位，用户传入时使用，否则为null
  /// [cmd] 命令字段，必须是有效的u8值
  /// [payload] 数据负载，每个元素必须是有效的u8值
  /// [checksum] 校验和，用户传入时使用，否则为null
  InterChipPacket({
    this.flag,
    this.len,
    this.lenH,
    required this.cmd,
    required this.payload,
    this.checksum,
  }) {
    _validateFields();
  }

  /// 验证字段有效性
  void _validateFields() {
    if (flag != null && !_isValidU8(flag!)) {
      throw ArgumentError('Flag must be a valid u8 value (0-255)');
    }
    if (len != null && !_isValidU8(len!)) {
      throw ArgumentError('Len must be a valid u8 value (0-255)');
    }
    if (lenH != null && !_isValidU8(lenH!)) {
      throw ArgumentError('LenH must be a valid u8 value (0-255)');
    }
    if (!_isValidU8(cmd.value)) {
      throw ArgumentError('Cmd must be a valid u8 value (0-255)');
    }
    if (checksum != null && !_isValidU8(checksum!)) {
      throw ArgumentError('Checksum must be a valid u8 value (0-255)');
    }
    for (int i = 0; i < payload.length; i++) {
      if (!_isValidU8(payload[i])) {
        throw ArgumentError('Payload[$i] must be a valid u8 value (0-255)');
      }
    }
  }

  /// 检查是否为有效的u8值
  bool _isValidU8(int value) {
    return value >= 0 && value <= 255;
  }

  /// 获取标志位对象（如果flag不为null）
  InterChipFlags? get flags {
    if (flag == null) return null;
    return InterChipFlags.fromFlag(flag!);
  }

  /// 计算总负载长度（包含cmd字段）
  /// 如果len和lenH都有值，则根据是否为长帧模式计算
  /// 否则返回实际的payload长度+1
  int get totalPayloadLength {
    if (len != null) {
      final isLongFrame = flags?.isLongFrame ?? false;
      if (isLongFrame && lenH != null) {
        return PacketUtils.bytesToInt16(len!, lenH!);
      } else {
        return len!;
      }
    }
    // 如果没有len字段，返回实际长度
    return payload.length + 1; // +1 for cmd field
  }

  /// 创建数据包的副本
  InterChipPacket copyWith({
    int? flag,
    int? len,
    int? lenH,
    InterChipCmds? cmd,
    List<int>? payload,
    int? checksum,
  }) {
    return InterChipPacket(
      flag: flag ?? this.flag,
      len: len ?? this.len,
      lenH: lenH ?? this.lenH,
      cmd: cmd ?? this.cmd,
      payload: payload ?? List<int>.from(this.payload),
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  String toString() {
    return 'InterChipPacket{'
        'flag: ${flag != null ? '0x${flag!.toRadixString(16).padLeft(2, '0')}' : 'null'}, '
        'len: ${len ?? 'null'}, '
        'lenH: ${lenH ?? 'null'}, '
        'cmd: 0x${cmd.value.toRadixString(16).padLeft(2, '0')}, '
        'payload: [${payload.map((e) => '0x${e.toRadixString(16).padLeft(2, '0')}').join(', ')}], '
        'checksum: ${checksum != null ? '0x${checksum!.toRadixString(16).padLeft(2, '0')}' : 'null'}'
        '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InterChipPacket) return false;

    return flag == other.flag &&
        len == other.len &&
        lenH == other.lenH &&
        cmd == other.cmd &&
        checksum == other.checksum &&
        _listEquals(payload, other.payload);
  }

  @override
  int get hashCode {
    return Object.hash(flag, len, lenH, cmd, checksum, Object.hashAll(payload));
  }

  /// 比较两个列表是否相等
  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 数据包标志位解析结构
///
/// Flag字段的位定义（按照协议文档）：
/// |7|6|5|4|3|2|1|0|
/// |reserve|LongFrame|reserve|ChecksumEnable|reserve|reserve|reserve|reserve|
class InterChipFlags {
  /// 是否启用长帧模式（LenH字段）- 第6位
  final bool isLongFrame;

  /// 是否启用校验和 - 第4位
  final bool checksumEnable;

  /// 构造函数
  const InterChipFlags(
      {required this.isLongFrame, required this.checksumEnable});

  /// 从flag字节创建InterChipFlags对象
  factory InterChipFlags.fromFlag(int flag) {
    return InterChipFlags(
      isLongFrame: (flag & PacketConstants.FLAG_LONG) != 0,
      checksumEnable: (flag & PacketConstants.FLAG_CHECKSUM) != 0,
    );
  }

  /// 转换为flag字节
  int encode() {
    int flag = 0;
    if (isLongFrame) flag |= PacketConstants.FLAG_LONG;
    if (checksumEnable) flag |= PacketConstants.FLAG_CHECKSUM;
    return flag;
  }

  /// 将整型标志位转换为 InterChipFlags 对象（与 encode 的反向操作）
  ///
  /// 参数说明：
  /// - flag：整型标志位（8位），按照协议位定义；
  ///   - 第6位（PacketConstants.FLAG_LONG）：是否启用长帧模式（LenH 字段）
  ///   - 第4位（PacketConstants.FLAG_CHECKSUM）：是否启用校验和
  ///
  /// 返回值：
  /// - InterChipFlags：包含 isLongFrame 与 checksumEnable 两个布尔字段的标志位对象
  static InterChipFlags decode(int flag) {
    // 复用 fromFlag 的逻辑，确保行为一致
    return InterChipFlags.fromFlag(flag);
  }

  @override
  String toString() {
    return 'InterChipFlags{isLongFrame: $isLongFrame, checksumEnable: $checksumEnable}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InterChipFlags) return false;
    return isLongFrame == other.isLongFrame &&
        checksumEnable == other.checksumEnable;
  }

  @override
  int get hashCode => Object.hash(isLongFrame, checksumEnable);
}
