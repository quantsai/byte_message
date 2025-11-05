import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码设置推杆速度（Set PushRod Speed）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeSetPushRodSpeedReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK（无第三层载荷）”的一层原始字节流，
///   并通过 ControlBusFactory.decodeSetPushRodSpeedAck 解码为 Ack 业务模型；
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：设置推杆速度请求（第三层负载为四个 s32 BE）
  final requestBytes = factory.encodeSetPushRodSpeedReq(
    a: 16,
    b: 32,
    c: 256,
    d: 0,
  );
  print('Encode SetPushRodSpeedReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK，无第三层载荷）
  final ackPacket =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: const <int>[]);
  final rawResponse = InterChipEncoder().encode(ackPacket);

  final res = factory.decodeSetPushRodSpeedAck(rawResponse);
  print('Decode.status: ${res.status}');
  print('Decode.data is Ack? ${res.data != null}');
}
