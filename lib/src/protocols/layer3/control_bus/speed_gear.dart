/// 控制总线第三层协议：速度档位（Speed Gear）
///
/// 文档参考：control.md#L169-194
/// - 请求：指令编号 0x3E，第三层请求负载为空（无数据）。
/// - 应答：速度档位 u8（0x00..0x05）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.speed_gear;

import 'package:byte_message/src/utils/validation.dart';

/// 速度档位枚举
///
/// 定义：
/// - gear0：0x00
/// - gear1：0x01
/// - gear2：0x02
/// - gear3：0x03
/// - gear4：0x04
/// - gear5：0x05
enum SpeedGear {
  gear0(0x00),
  gear1(0x01),
  gear2(0x02),
  gear3(0x03),
  gear4(0x04),
  gear5(0x05);

  /// 对应的 u8 值
  final int value;
  const SpeedGear(this.value);

  /// 将 u8 映射为枚举值
  ///
  /// 参数：
  /// - v：u8 档位（0..255）
  /// 返回：SpeedGear 对应枚举
  /// 异常：当 v 不在 0x00..0x05 范围内时抛出 ArgumentError
  static SpeedGear fromValue(int v) {
    ensureU8(v, name: 'SpeedGear');
    for (final g in SpeedGear.values) {
      if (g.value == v) return g;
    }
    throw ArgumentError('Invalid SpeedGear u8 value: 0x${v.toRadixString(16)}');
  }
}

/// 第三层：速度档位请求
class SpeedGearReq {
  /// 编码第三层请求负载
  ///
  /// 功能：速度档位请求在第三层无负载，返回空数组。
  /// 参数：无
  /// 返回：List<int> 空数组 []
  List<int> encode() {
    return const <int>[];
  }
}

/// 第三层：速度档位应答
class SpeedGearRes {
  /// 档位枚举
  final SpeedGear gear;

  /// 构造函数
  ///
  /// 参数：
  /// - gear：速度档位枚举
  const SpeedGearRes({required this.gear});

  /// 从第三层字节数组解析速度档位应答
  ///
  /// 功能：解析长度为 1 的载荷，返回 SpeedGearRes。
  /// 参数：
  /// - bytes：第三层载荷，必须仅包含 1 字节（u8 档位）。
  /// 返回：SpeedGearRes
  /// 异常：
  /// - ArgumentError：当载荷长度不是 1 或档位值不在 0x00..0x05 时抛出。
  static SpeedGearRes fromBytes(List<int> bytes) {
    if (bytes.length != 1) {
      throw ArgumentError(
        'Invalid L3 speed gear payload length: expected 1, got ${bytes.length}',
      );
    }
    final v = bytes[0] & 0xFF; // u8
    final gear = SpeedGear.fromValue(v);
    return SpeedGearRes(gear: gear);
  }

  @override
  String toString() =>
      'SpeedGearRes{gear: ${gear.name}(0x${gear.value.toRadixString(16)})}';
}
