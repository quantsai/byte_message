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
  example5();
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

/// 标志位 PacketFlags 使用示例
///
/// 功能描述：
/// - 展示 PacketFlags 的位定义、编码与解码（与 encode 的反向操作）
/// - 通过 PacketFlags.encode() 生成整型标志位，再使用 PacketFlags.decode()/fromFlag 解析回对象
///
/// 参数：
/// - 无
///
/// 返回值：
/// - void（仅打印示例结果）
void example5() {
  print('');
  print('5. 标志位 PacketFlags 使用示例');
  print('=' * 100);

  // 参见类定义位置：/Users/caiquan/code/lib/byte_message/lib/src/models/packet_models.dart#L170-170
  // 位定义（协议）：
  // |7|6|5|4|3|2|1|0|
  // |reserve|LongFrame|reserve|ChecksumEnable|reserve|reserve|reserve|reserve|

  // 示例一：长帧且启用校验和
  final flags2 = PacketFlags(isLongFrame: true, checksumEnable: true);
  final encoded2 = flags2.encode();
  final decoded2 = PacketFlags.decode(encoded2);
  print(
      '示例二: flags=$flags2 -> encode=0x${encoded2.toRadixString(16).padLeft(2, '0')} -> decode=$decoded2');

  // 示例二：直接从整型标志位创建（工厂方法 fromFlag）
  final fromFlag =
      PacketFlags.fromFlag(0x50); // 0x40: LongFrame, 0x10: ChecksumEnable
  print('示例三: fromFlag(0x50) -> $fromFlag');

  print('');
}
