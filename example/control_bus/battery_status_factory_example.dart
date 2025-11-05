import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码电量与充电状态（Battery Status）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeBatteryStatusReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK + 第三层载荷（2 字节）”的一层原始字节流，并通过 ControlBusFactory.decodeBatteryStatusRes 解码为业务模型；
/// - 展示充电状态枚举的解析规则：bit0 表示充电中；0x02 或电量 100% 表示充满；其余为不在充电。
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：电量与充电状态请求（第三层负载为空）
  final requestBytes = factory.encodeBatteryStatusReq();
  print('Encode GetBatteryStatusReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK + 第三层载荷2字节）
  // 示例一：电量 85%，状态 0x03（bit0=1充电中 + bit1=1已插电）
  final l3Payload1 = <int>[85, 0x03];
  final ackPacket1 =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3Payload1);
  final rawResponse1 = InterChipEncoder().encode(ackPacket1);

  final res1 = factory.decodeBatteryStatusRes(rawResponse1);
  if (res1.data != null) {
    final d = res1.data!;
    print('Decode1.status: ${res1.status}');
    print('Decode1.percent: ${d.batteryPercent}%');
    print('Decode1.charge: ${d.chargeStatus}'); // ChargeStatus.charging
  }

  // 示例二：电量 100%，状态 0x00（未充电，按百分比判定为充满）
  final l3Payload2 = <int>[100, 0x00];
  final ackPacket2 =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3Payload2);
  final rawResponse2 = InterChipEncoder().encode(ackPacket2);

  final res2 = factory.decodeBatteryStatusRes(rawResponse2);
  if (res2.data != null) {
    final d = res2.data!;
    print('Decode2.status: ${res2.status}');
    print('Decode2.percent: ${d.batteryPercent}%');
    print('Decode2.charge: ${d.chargeStatus}'); // ChargeStatus.chargeComplete
  }

  // 示例三：电量 90%，状态 0x02（仅插电、不充电，按规则判定为充满）
  final l3Payload3 = <int>[90, 0x02];
  final ackPacket3 =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3Payload3);
  final rawResponse3 = InterChipEncoder().encode(ackPacket3);

  final res3 = factory.decodeBatteryStatusRes(rawResponse3);
  if (res3.data != null) {
    final d = res3.data!;
    print('Decode3.status: ${res3.status}');
    print('Decode3.percent: ${d.batteryPercent}%');
    print('Decode3.charge: ${d.chargeStatus}'); // ChargeStatus.chargeComplete
  }
}
