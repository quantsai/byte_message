import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码设置操作模式（Set Operating Mode）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeSetOperatingModeReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK（无第三层载荷）”的一层原始字节流，
///   并通过 ControlBusFactory.decodeSetOperatingModeAck 解码为 Ack 业务模型；
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：设置操作模式请求（第三层负载为 1 字节 u8）
  final requestBytes = factory.encodeSetOperatingModeReq(
    mode: OperatingMode.selfBalance,
  );
  print('Encode SetOperatingModeReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK，无第三层载荷）
  final ackPacket =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: const <int>[]);
  final rawResponse = InterChipEncoder().encode(ackPacket);

  final res = factory.decodeSetOperatingModeAck(rawResponse);
  print('Decode.status: ${res.status}');
  print('Decode.data is Ack? ${res.data != null}');
}
