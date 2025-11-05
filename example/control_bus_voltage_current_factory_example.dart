import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码电压与电流（Voltage & Current）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeElectricalMetricsReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK + 第三层载荷（8 字节，s32 BE）”的一层原始字节流，并通过 ControlBusFactory.decodeElectricalMetricsRes 解码为业务模型；
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：电压与电流请求（第三层负载为空）
  final requestBytes = factory.encodeElectricalMetricsReq();
  print('Encode ElectricalMetricsReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK + 第三层载荷8字节）
  // 示例一：电压 12000 mV（0x00002EE0），电流 -500 mA（0xFFFFFE0C，按 s32 BE）
  final voltage1 = [0x00, 0x00, 0x2E, 0xE0];
  final current1 = [0x00, 0x00, 0x01, 0x00];
  final l3Payload1 = <int>[...voltage1, ...current1];
  final ackPacket1 =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3Payload1);
  final rawResponse1 = InterChipEncoder().encode(ackPacket1);

  final res1 = factory.decodeElectricalMetricsRes(rawResponse1);
  if (res1.data != null) {
    final d = res1.data!;
    print('Decode1.status: ${res1.status}');
    print('Decode1.voltage(mV): ${d.voltageMv}');
    print('Decode1.current(mA): ${d.currentMa}');
  }
}
