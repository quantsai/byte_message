import 'package:byte_message/byte_message.dart';

/// 示例：DFU 获取设备信息（Get Device Info）—— 工厂编解码演示
///
/// 功能描述：
/// - 演示如何使用 DfuFactory 将“获取设备信息”请求编码为完整的一层字节流；
/// - 演示如何解码设备返回的 AckOK（payload 长度为 33 字节）应答为第三层模型。
void main() {
  final factory = DfuFactory();

  // 1) 编码获取设备信息请求：DfuCmd=0x01, DfuVersion=0x01
  final req = factory.encodeGetDeviceInfoReq();
  print('GetDeviceInfoReq L1 bytes: $req');

  // 2) 模拟设备返回 AckOK（payload 为 33 字节），此处构造一个伪数据用于演示
  // 字段顺序：u8, u16, u16, u16, u32, u32, u32, u32, u16, u32, u32
  final payload = <int>[];
  payload.add(0x01); // DfuPkgVersion u8
  payload.addAll([0x00, 0x00]); // BootloaderVersion u16
  payload.addAll([0x00, 0x00]); // BootloaderPageCnt u16
  payload.addAll([0x00, 0x00]); // DeviceType u16
  payload.addAll([0x00, 0x00, 0x00, 0x00]); // PageNum u32
  payload.addAll([0x00, 0x00, 0x00, 0x00]); // PageSize u32
  // RomVersion u32（BE）：四字节 [b0,b1,b2,b3]，b0 不用，版本号 = b1.b2.b3
  // 示例：[0x00,0x02,0x11,0x06] -> 2.17.06
  payload.addAll([0x00, 0x02, 0x11, 0x06]); // RomVersion u32 -> 2.17.06
  payload.addAll([0x00, 0x00, 0x00, 0x00]); // VenderInfo u32
  payload.addAll([0x00, 0x00]); // HardwareVersion u16
  payload.addAll([0x00, 0x00, 0xFF, 0xFF]); // DfuDeviceFlag u32
  payload.addAll([0x00, 0x00, 0x04, 0x88]); // DfuDevicePowerVolt u32

  final ackPacket = InterChipPacket(
    cmd: InterChipCmds.ackOk,
    payload: payload,
  );
  final rawAck = InterChipEncoder().encode(ackPacket);

  // 3) 解码应答
  final res = factory.decodeGetDeviceInfoRes(rawAck);
  print('Decode status: ${res.status}, data: ${res.data}');
}
