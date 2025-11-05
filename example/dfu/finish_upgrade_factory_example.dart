import 'package:byte_message/byte_message.dart';

/// 示例：DFU 完成升级（Finish Upgrade）—— 工厂编解码演示
///
/// 功能描述：
/// - 演示如何使用 DfuFactory 将“完成升级”请求编码为完整的一层字节流；
/// - 演示如何解码设备返回的 AckOK（payload 长度为 2 字节）应答为第三层模型。
void main() {
  final factory = DfuFactory();

  // 1) 编码完成升级请求：DfuCmd=0x03, DfuVersion=0x01
  final req = factory.encodeFinishUpgradeReq();
  print('FinishUpgradeReq L1 bytes: $req');

  // 2) 模拟设备返回 AckOK（payload 为 2 字节），此处构造一个伪数据用于演示
  // 字段顺序：DfuPkgVersion u8, DfuOpResult u8
  final payload = <int>[];
  payload.add(0x01); // DfuPkgVersion u8
  payload.add(0x00); // DfuOpResult u8 -> 0x00 (OK)

  final ackPacket = InterChipPacket(
    cmd: InterChipCmds.ackOk,
    payload: payload,
  );
  final rawAck = InterChipEncoder().encode(ackPacket);

  // 3) 解码应答
  final res = factory.decodeFinishUpgradeRes(rawAck);
  print('Decode status: ${res.status}, data: ${res.data}');
}