/// 控制总线第三层协议：设置推杆速度（Set PushRod Speed）
///
/// 文档参考：control.md#L214-231（推杆控制 0x42）
/// - 请求：指令编号 0x42，第三层请求负载为四个有符号 32 位整数（s32，大端序），
///   分别表示推杆 A/B/C/D 的速度。
/// - 应答：无第三层载荷（AckOK），仅通过一层 Cmd 表示成功。
///
/// 设计约束：
/// - 仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.set_pushrod_speed;

import 'package:byte_message/src/utils/byte_packing.dart';

/// 第三层：设置推杆速度请求
class SetPushRodSpeedReq {
  /// 推杆 A 速度（s32 BE）
  final double speedA;

  /// 推杆 B 速度（s32 BE）
  final double speedB;

  /// 推杆 C 速度（s32 BE）
  final double speedC;

  /// 推杆 D 速度（s32 BE）
  final double speedD;

  /// 构造函数
  ///
  /// 参数：
  /// - [speedA] 推杆 A 速度（s32）
  /// - [speedB] 推杆 B 速度（s32）
  /// - [speedC] 推杆 C 速度（s32）
  /// - [speedD] 推杆 D 速度（s32）
  const SetPushRodSpeedReq({
    required this.speedA,
    required this.speedB,
    required this.speedC,
    required this.speedD,
  });

  /// 编码第三层请求负载（s32 BE: A/B/C/D）
  ///
  /// 返回：长度 16 字节的数组 [A(4) | B(4) | C(4) | D(4)]
  List<int> encode() {
    final bytes = <int>[];
    bytes.addAll(packF32BE(speedA));
    bytes.addAll(packF32BE(speedB));
    bytes.addAll(packF32BE(speedC));
    bytes.addAll(packF32BE(speedD));
    return bytes;
  }
}

/// 第三层：设置推杆速度应答（Ack）
///
/// 说明：该应答不携带第三层载荷，仅通过一层 Cmd=AckOK 表示成功。
class SetPushRodSpeedAck {
  const SetPushRodSpeedAck();

  /// 从第三层字节解析 Ack
  ///
  /// 要求：载荷长度必须为 0。
  /// 返回：常量 Ack 对象用于表示成功
  static SetPushRodSpeedAck fromBytes(List<int> bytes) {
    if (bytes.isNotEmpty) {
      throw ArgumentError(
          'Invalid L3 set pushrod speed ack payload length: expected 0, got ${bytes.length}');
    }
    return const SetPushRodSpeedAck();
  }
}
