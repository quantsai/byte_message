import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 进行三层组合的编码与解码
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeConnectionReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK + 第三层载荷（长度28，全零）”的原始一层字节流，并通过 ControlBusFactory.decodeConnectionRes 解码为业务模型；
///
/// 注意：
/// - 示例中的解码原始字节流 rawResponseBytes 为本地模拟构造，真实场景应来自设备返回的数据。
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：设备连接请求（第三层协议版本默认 0x02）
  final requestBytes = factory.encodeConnectionReq(protocolVersion: 0x02);
  print('Encode: $requestBytes');

  // 2) 解码：模拟设备返回的一层原始字节流（AckOK + 第三层载荷长度28）
  // 第三层载荷格式：型号(12字节ASCII) + 固件版本(u16) + 硬件版本(u16) + 序列号(3个u32，大端)
  // 这里使用“全零”作为演示载荷，长度必须为 28
  final l3Payload = List<int>.filled(12 + 2 + 2 + 4 * 3, 0);

  // 构造一层应答包（AckOK）并编码为原始字节流
  final ackPacket = InterChipPacket(
    cmd: InterChipCmds.ackOk,
    payload: l3Payload,
  );
  final rawResponseBytes = InterChipEncoder().encode(ackPacket);

  // 进行解码（一次性从一层原始字节流还原第三层模型）
  final result = factory.decodeConnectionRes(rawResponseBytes);

  // 判断状态并输出结果
  if (result.status == InterChipCmds.ackOk && result.data != null) {
    final resp = result.data!;
    print('Decode.status: ${result.status}');
    print('Decode.data: ${result.data}');
  } else {
    print('Decode Connection Response -> NOT OK, status: ${result.status}');
  }
}
