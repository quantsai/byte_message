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
  payload.addAll(packU16BE(composeVersion(major: 1, minor: 2, revision: 3))); // BootloaderVersion u16
  payload.addAll(packU16BE(0x0010)); // BootloaderPageCnt u16
  payload.addAll(packU16BE(0x0001)); // DeviceType u16
  payload.addAll(packU32BE(100)); // PageNum u32
  payload.addAll(packU32BE(4096)); // PageSize u32
  payload.addAll(packU32BE(0x01020304)); // RomVersion u32
  payload.addAll(packU32BE(0x55667788)); // VenderInfo u32
  payload.addAll(packU16BE(composeVersion(major: 2, minor: 0, revision: 1))); // HardwareVersion u16
  payload.addAll(packU32BE(0x0000FFFF)); // DfuDeviceFlag u32
  payload.addAll(packU32BE(12000)); // DfuDevicePowerVolt u32

  final ackPacket = InterChipPacket(
    cmd: InterChipCmds.ackOk,
    payload: payload,
  );
  final rawAck = InterChipEncoder().encode(ackPacket);

  // 3) 解码应答
  final res = factory.decodeGetDeviceInfoRes(rawAck);
  print('Decode status: ${res.status}, data: ${res.data}');
}