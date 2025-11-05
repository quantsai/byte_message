/// 控制总线第三层协议：电压与电流（Voltage & Current）
///
/// 文档参考：control.md#L109-123
/// - 请求：指令编号 0x36，第三层请求负载为空（无数据）。
/// - 应答：两段 s32（签名32位，大端序）：电压（mV）、电流（mA）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.voltage_current;

import 'package:byte_message/src/utils/byte_packing.dart';

/// 电压与电流请求（第三层）
///
/// 负责生成“电压与电流”请求的第三层负载字节。
/// 注意：该请求在第三层无负载（空数组）。
class ElectricalMetricsReq {
  /// 生成第三层请求负载（空内容）
  ///
  /// 返回：
  /// - List<int> 空数组（[]），表示第三层无负载内容。
  List<int> encode() {
    return const [];
  }
}

/// 电压与电流应答（第三层）
///
/// 负责解析“电压与电流”请求的第三层应答负载：电压（mV）与电流（mA），均为 s32（签名32位，大端）。
class ElectricalMetricsRes {
  /// 电压（毫伏，mV），签名 32 位整型
  final int voltageMv;

  /// 电流（毫安，mA），签名 32 位整型
  final int currentMa;

  /// 构造函数
  ///
  /// 参数：
  /// - [voltageMv] 电压（mV，s32）
  /// - [currentMa] 电流（mA，s32）
  ElectricalMetricsRes({required this.voltageMv, required this.currentMa});

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含第一层/第二层字段），总长度必须为 8 字节：
  ///   前 4 字节为电压（mV，s32 BE），后 4 字节为电流（mA，s32 BE）。
  ///
  /// 返回：
  /// - [ElectricalMetricsRes] 解析后的应答数据模型
  ///
  /// 异常：
  /// - [ArgumentError] 当长度不为 8 或字节不足时抛出
  static ElectricalMetricsRes fromBytes(List<int> bytes) {
    const expectedLength = 8;
    if (bytes.length < expectedLength) {
      throw ArgumentError(
        'Invalid voltage/current payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    // 读取签名 32 位（s32）的大端序数值，支持负电流（放电场景）。
    final voltage = readU32BE(bytes.sublist(0, 4));
    final current = readU32BE(bytes.sublist(4, 8));

    return ElectricalMetricsRes(voltageMv: voltage, currentMa: current);
  }

  @override
  String toString() {
    return 'ElectricalMetricsRes(voltageMv=$voltageMv, currentMa=$currentMa)';
  }
}
