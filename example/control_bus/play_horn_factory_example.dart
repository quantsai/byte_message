import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码播放喇叭（Play Horn）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodePlayHornReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK（无第三层载荷）”的一层原始字节流，
///   并通过 ControlBusFactory.decodePlayHornAck 解码为 Ack 业务模型；
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：播放喇叭请求（第三层负载为 u16 BE 毫秒）
  final requestBytes = factory.encodePlayHornReq(
    durationMs: 1500, // 1.5 秒，0x05DC
  );
  print('Encode PlayHornReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK，无第三层载荷）
  final ackPacket =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: const <int>[]);
  final rawResponse = InterChipEncoder().encode(ackPacket);

  final res = factory.decodePlayHornAck(rawResponse);
  print('Decode.status: ${res.status}');
  print('Decode.data is Ack? ${res.data != null}');
}

