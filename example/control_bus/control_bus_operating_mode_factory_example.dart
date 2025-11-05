import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码功能模式（Operating Mode）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeOperatingModeReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK + 第三层载荷（1 字节：u8 模式）”的一层原始字节流，
///   并通过 ControlBusFactory.decodeOperatingModeRes 解码为业务模型；
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：功能模式请求（第三层负载为空）
  final requestBytes = factory.encodeOperatingModeReq();
  print('Encode OperatingModeReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK + 第三层载荷1字节）
  // 示例：模式 0x01（自平衡模式）
  final mode = 0x01;
  final l3Payload = <int>[mode];
  final ackPacket = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3Payload);
  final rawResponse = InterChipEncoder().encode(ackPacket);

  final res = factory.decodeOperatingModeRes(rawResponse);
  if (res.data != null) {
    final d = res.data!;
    print('Decode.status: ${res.status}');
    print('OperatingMode(u8): ${d.mode}');
  }
}