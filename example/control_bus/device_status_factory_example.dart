import 'package:byte_message/byte_message.dart';

/// 示例：使用 ControlBusFactory 编码/解码机器状态（Device Status）
///
/// 功能描述：
/// - 演示如何通过 ControlBusFactory.encodeDeviceStatusReq 生成一次性可发送的一层完整字节流；
/// - 演示如何构造一个模拟的“应答 OK + 第三层载荷（5 字节：u8 状态 + u32 错误码 BE）”的一层原始字节流，
///   并通过 ControlBusFactory.decodeDeviceStatusRes 解码为业务模型；
///
/// 参数：无
/// 返回：无（打印示例输出）
void main() {
  final factory = ControlBusFactory();

  // 1) 编码：机器状态请求（第三层负载为空）
  final requestBytes = factory.encodeDeviceStatusReq();
  print('Encode GetDeviceStatusReq: $requestBytes');

  // 2) 解码：构造模拟的一层应答字节流（AckOK + 第三层载荷5字节）
  // 示例：状态 0x00（OK），错误码 0x00000000
  final status = 0x02;
  final errorCode = [0x00, 0x00, 0x01, 0x00];
  final l3Payload = <int>[status, ...errorCode];
  final ackPacket =
      InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3Payload);
  final rawResponse = InterChipEncoder().encode(ackPacket);

  final res = factory.decodeDeviceStatusRes(rawResponse);
  if (res.data != null) {
    final d = res.data!;
    print('Decode.status: ${res.status}');
    print('MachineStatus(u8): ${d.deviceStatus}');
    print('ErrorCode(u32): ${d.errorCode}');
  }
}
