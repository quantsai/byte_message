/// Inter-chip协议编码解码库使用示例
///
/// 本示例展示了如何使用byte_message库进行inter-chip协议的编码和解码操作

import 'package:byte_message/byte_message.dart';

void main() {
  print('=== Inter-chip协议编码解码库使用示例 ===\n');

  example1();
  example2();
  example3();
  example4();
}

/// 自动短帧：flag、len、lenH、checksum
void example1() {
  print('');
  print('1. 自动短帧：flag、len、lenH、checksum');
  print('=' * 100);

  // 创建自动处理的编码器和解码器
  const encoder = InterChipEncoder();
  const decoder = InterChipDecoder();

  // 只提供cmd和payload，明确指定短帧+校验和
  final packet = InterChipPacket(
    cmd: PacketCommand.normal,
    payload: [0x01, 0x02, 0x03],
  );

  print('输入参数: cmd=${packet.cmd}, payload=${packet.payload}');

  // 编码
  final encodedData = encoder.encode(packet);

  print('编码结果: ${encodedData}');

  // 解码验证
  final decodedPacket = decoder.decode(encodedData);
  print('解码成功:$decodedPacket');

  print('');
}

/// 自动：flag、len、lenH、checksum
void example2() {
  print('');
  print('2. 自动长帧：flag、len、lenH、checksum');
  print('=' * 100);

  // 创建自动处理的编码器和解码器
  const encoder = InterChipEncoder();
  const decoder = InterChipDecoder();

  final packet = InterChipPacket(
    cmd: PacketCommand.normal,
    payload: List.generate(300, (index) => (index % 256)),
  );

  print('输入参数: cmd=${packet.cmd}, payload=${packet.payload}');

  // 编码
  final encodedData = encoder.encode(packet);

  print('编码结果: ${encodedData}');

  // 解码验证
  final decodedPacket = decoder.decode(encodedData);
  print('解码成功:$decodedPacket');
  print('');
}

/// 手动flag，自动len、lenH、checksum
void example3() {
  print('');
  print('3. 手动flag，自动len、lenH、checksum');
  print('=' * 100);

  // 创建自动处理的编码器和解码器
  const encoder = InterChipEncoder();
  const decoder = InterChipDecoder();

  // 只提供cmd和payload，生成3个元素的payload（短帧）
  final packet = InterChipPacket(
    flag: PacketFlags(isLongFrame: true, checksumEnable: true).encode(),
    cmd: PacketCommand.normal,
    payload: List.generate(3, (index) => (index % 256)),
  );

  print('输入参数: cmd=${packet.cmd}, payload=${packet.payload}');

  // 编码
  final encodedData = encoder.encode(packet);

  print('编码结果: ${encodedData}');

  // 解码验证
  final decodedPacket = decoder.decode(encodedData);
  print('解码成功:$decodedPacket');

  print('');
}

/// 全手动flag、len、lenH、checksum
/// 不推荐，手动设置flag、len、lenH、checksum的值容易冲突
void example4() {
  print('');
  print('4. 全手动flag、len、lenH、checksum');
  print('不推荐，flag、len、lenH、checksum的值容易冲突');
  print('=' * 100);

  // 创建自动处理的编码器和解码器
  const encoder = InterChipEncoder();
  const decoder = InterChipDecoder();

  final packet = InterChipPacket(
    flag: PacketFlags(isLongFrame: true, checksumEnable: true).encode(),
    len: 0,
    lenH: 4,
    cmd: PacketCommand.normal,
    payload: List.generate(3, (index) => (index % 256)),
    checksum: 0xaf,
  );

  print('输入参数: cmd=${packet.cmd}, payload=${packet.payload}');

  // 编码
  final encodedData = encoder.encode(packet);

  print('编码结果: ${encodedData}');

  // 解码验证
  final decodedPacket = decoder.decode(encodedData);
  print('解码成功:$decodedPacket');

  print('');
}
