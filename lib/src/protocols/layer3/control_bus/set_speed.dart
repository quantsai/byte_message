/// 控制总线第三层协议：速度控制（Speed Control）
///
/// 文档参考：control.md#L197-213
/// - 请求：指令编号 0x41，第三层请求负载为两个浮点数（线速度 m/s、角速度 r/s），均为 float32 大端序（BE）。
/// - 应答：无（仅 AckOK，无第三层载荷）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.speed_control;

import 'package:byte_message/src/utils/byte_packing.dart';

/// 第三层：速度控制请求
class SetSpeedReq {
  /// 线速度（m/s），以 float32 BE 编码
  final double linearVelocity;

  /// 角速度（r/s），以 float32 BE 编码
  final double angularVelocity;

  /// 构造函数
  ///
  /// 参数：
  /// - [linearVelocity] 线速度（m/s）
  /// - [angularVelocity] 角速度（r/s）
  const SetSpeedReq(
      {required this.linearVelocity, required this.angularVelocity});

  /// 编码第三层请求负载（float32 BE: 线速度 + 角速度）
  ///
  /// 返回：长度 8 字节的数组 [lin_f32_be | ang_f32_be]
  List<int> encode() {
    final lin = packF32BE(linearVelocity);
    final ang = packF32BE(angularVelocity);
    return <int>[...lin, ...ang];
  }
}

/// 第三层：速度控制应答（Ack）
///
/// 说明：该应答不携带第三层载荷，仅通过一层 Cmd=AckOK 表示成功。
class SetSpeedAck {
  const SetSpeedAck();

  /// 从第三层字节解析 Ack
  ///
  /// 要求：载荷长度必须为 0。
  /// 返回：常量 Ack 对象用于表示成功
  static SetSpeedAck fromBytes(List<int> bytes) {
    if (bytes.isNotEmpty) {
      throw ArgumentError(
          'Invalid L3 speed control ack payload length: expected 0, got ${bytes.length}');
    }
    return const SetSpeedAck();
  }
}
