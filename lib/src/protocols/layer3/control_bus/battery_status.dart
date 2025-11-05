/// 控制总线第三层协议：电量与充电状态（Battery Status）
///
/// 本文件实现第三层协议的两部分：
/// - 请求编码：电量/充电状态请求在第三层无负载（空内容），由更高层负责组帧（第二层 cmd=0x30，第一层包装）。
/// - 应答解码：从第三层字节序列解析电量百分比（u8，0..100）与充电状态（u8，按位定义）。
///
/// 设计约束：
/// - 与前两层完全解耦：仅处理第三层的内容字节，不包含 Cmd / CbCmd 等字段。
library byte_message.l3.control_bus.battery_status;

import 'package:byte_message/src/utils/validation.dart';

/// 电量与充电状态请求（第三层）
///
/// 负责生成“电量与充电状态”请求的第三层负载字节。
/// 注意：该请求在第三层无负载（空数组）。
class BatteryStatusReq {
  /// 生成第三层请求负载（空内容）
  ///
  /// 返回：
  /// - List<int> 空数组（[]），表示第三层无负载内容。
  List<int> encode() {
    return const [];
  }
}

/// 电量与充电状态应答（第三层）
///
/// 负责解析“电量与充电状态”请求的第三层应答负载：电量百分比（u8）与充电状态（u8）。
class BatteryStatusRes {
  /// 电量百分比（0..100）
  final int batteryPercent;

  /// 充电状态（u8，按位定义）
  /// bit0: 是否充电
  /// bit1: 是否插电
  /// bit2: （文档标注为废弃/暂不使用）是否锁定充电桩
  /// bit3: （文档标注为废弃/暂不使用）是否探测到充电桩
  /// bit4: （文档标注为废弃/暂不使用）是否通讯上充电桩
  /// bit5: （文档标注为废弃/暂不使用）是否在和充电桩协商
  /// bit6-7: 预留
  final ChargeStatus chargeStatus;

  /// 构造函数
  ///
  /// 参数：
  /// - [batteryPercent] 电量百分比（0..100）
  /// - [chargeStatus] 充电状态（u8，0..255）
  BatteryStatusRes({required this.batteryPercent, required this.chargeStatus});

  /// 是否正在充电（chargeStatus 的 bit0）
  // bool get isCharging => (chargeStatus & 0x01) != 0;

  // /// 是否插电（chargeStatus 的 bit1）
  // bool get isPluggedIn => (chargeStatus & 0x02) != 0;

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含第一层/第二层字段），总长度必须为 2 字节：
  ///   第 0 字节为电量百分比（u8，0..100），第 1 字节为充电状态（u8，按位定义）。
  ///
  /// 返回：
  /// - [BatteryStatusRes] 解析后的应答数据模型
  ///
  /// 异常：
  /// - [ArgumentError] 当长度不为 2 或字节不足时抛出
  /// - [RangeError] 当电量百分比超出 0..100 或充电状态超出 u8 范围时抛出
  static BatteryStatusRes fromBytes(List<int> bytes) {
    const expectedLength = 2;
    if (bytes.length < expectedLength) {
      throw ArgumentError(
        'Invalid battery status payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    final percentByte = bytes[0];
    final statusByte = bytes[1];

    // 范围校验：百分比 0..100，状态为 u8
    ensureU8(percentByte, name: 'batteryPercent');
    ensureU8(statusByte, name: 'chargeStatus');

    if (percentByte < 0 || percentByte > 100) {
      throw RangeError('batteryPercent must be in 0..100, got $percentByte');
    }

    final status = parseChargeStatus(statusByte, percentByte);

    return BatteryStatusRes(batteryPercent: percentByte, chargeStatus: status);
  }

  /// 将原始充电状态字节与电量百分比映射为业务枚举（ChargeStatus）
  ///
  /// 规则参考 control.md#L94-107：
  /// - bit0: 是否充电（1 表示正在充电）
  /// - bit1: 是否插电（1 表示已插电）
  /// - bit2..5: 废弃/暂不使用（保留）
  /// - bit6..7: 预留
  ///
  /// 充满判定（两种逻辑）：
  /// - 原始字节为 0x02（仅插电、不充电）
  /// - 或电量百分比 >= 100
  static ChargeStatus parseChargeStatus(int statusByte, int percentByte) {
    // 正在充电优先判断（bit0 == 1）
    if ((statusByte & 0x01) != 0) {
      return ChargeStatus.charging;
    }

    // 充满的两种判定方式
    if (statusByte == 0x02 || percentByte >= 100) {
      return ChargeStatus.chargeComplete;
    }

    // 其余统一归为“不在充电”
    return ChargeStatus.notCharging;
  }
}

enum ChargeStatus {
  notCharging,
  charging,
  chargeComplete,
}
