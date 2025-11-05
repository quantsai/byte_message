import 'package:byte_message/byte_message.dart';

/// 示例：设置摇杆（Set Joystick）—— 工厂编解码演示
///
/// 功能描述：
/// - 演示如何使用 ControlBusFactory 将 X/Y/Z 三轴偏量（均为 -100..100 的百分比）编码为完整的一层字节流；
/// - 演示如何解码设备返回的 AckOK（无第三层负载）。
void main() {
  final factory = ControlBusFactory();

  // 1) 编码设置摇杆请求：X=+10，Y=-5，Z=0（s16 BE * 3，CbCmd=0x81）
  final req = factory.encodeSetJoystickReq(x: 1, y: -2, z: 0);
  print('SetJoystickReq L1 bytes: $req');

  // 2) 模拟设备返回 AckOK（无第三层负载）
  final ackPacket = InterChipPacket(
    cmd: InterChipCmds.ackOk,
    payload: const <int>[],
  );
  final ackRaw = InterChipEncoder().encode(ackPacket);

  // 3) 解码设置摇杆应答
  final res = factory.decodeSetJoystickAck(ackRaw);
  print('Decode status: ${res.status}, data: ${res.data}');
}
