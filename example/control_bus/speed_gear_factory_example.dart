import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码速度档位（Speed Gear）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeSpeedGearReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK + 第三层载荷（1 字节：u8 档位）”的一层原始字节流，
///   并通过 ControlBusFactory.decodeSpeedGearRes 解码为业务模型；
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：速度档位请求（第三层负载为空）
  final requestBytes = factory.encodeSpeedGearReq();
  print('Encode SpeedGearReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK + 第三层载荷1字节）
  // 示例：档位 0x03（3 档）
  final gearU8 = 0x03;
  final l3Payload = <int>[gearU8];
  final ackPacket = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3Payload);
  final rawResponse = InterChipEncoder().encode(ackPacket);

  final res = factory.decodeSpeedGearRes(rawResponse);
  if (res.data != null) {
    final d = res.data!;
    print('Decode.status: ${res.status}');
    print('SpeedGear(enum): ${d.gear.name} (u8=0x${d.gear.value.toRadixString(16)})');
  }
}