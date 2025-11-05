import 'package:byte_message/byte_message.dart';

/// 示例：设置折叠/展开（Set Fold State）—— 工厂编解码演示
///
/// 功能描述：
/// - 演示如何使用 ControlBusFactory 将折叠/展开状态（u8：0x00/0x01）编码为完整的一层字节流；
/// - 演示如何解码设备返回的 AckOK（无第三层负载）。
void main() {
  final factory = ControlBusFactory();

  // 1) 编码设置折叠请求：Fold（0x00），CbCmd=0x82
  final reqFold = factory.encodeSetFoldStateReq(state: FoldState.fold);
  print('SetFoldStateReq(Fold) L1 bytes: $reqFold');

  // 2) 编码设置展开请求：Unfold（0x01），CbCmd=0x82
  final reqUnfold = factory.encodeSetFoldStateReq(state: FoldState.unfold);
  print('SetFoldStateReq(Unfold) L1 bytes: $reqUnfold');

  // 3) 模拟设备返回 AckOK（无第三层负载）
  final ackPacket = InterChipPacket(
    cmd: InterChipCmds.ackOk,
    payload: const <int>[],
  );
  final ackRaw = InterChipEncoder().encode(ackPacket);

  // 4) 解码设置折叠/展开应答
  final res = factory.decodeSetFoldStateAck(ackRaw);
  print('Decode status: ${res.status}, data: ${res.data}');
}
