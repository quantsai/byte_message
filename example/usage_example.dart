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
  example6();
  example7();
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

/// 二层协议：Control Bus 编码与解码示例
///
/// 功能描述：
/// - 使用 ControlBusMessage 构造二层负载（CbCmd + CbPayload）
/// - 通过 ControlBusEncoder 生成一层 InterChipPacket 并序列化
/// - 使用 InterChipDecoder + ControlBusDecoder 反解得到二层结构
void example6() {
  print('');
  print('6. 二层协议：Control Bus 编码与解码示例');
  print('=' * 100);

  const interEncoder = InterChipEncoder();
  const interDecoder = InterChipDecoder();
  final cbEncoder = ControlBusEncoder();
  final cbDecoder = ControlBusDecoder();

  // 构造 Control Bus 二层消息：CbCmd=0x01，负载 [0xAA, 0xBB]
  final cbMsg = ControlBusMessage(cbCmd: 0x01, cbPayload: [0xAA, 0xBB]);
  print('二层object: $cbMsg');

  // 仅编码二层内容（不含一层字段）
  final cbPayloadBytes = cbEncoder.encode(cbMsg);
  print('二层encode: $cbPayloadBytes');

  // 生成一层数据包（Cmd 固定为 0xF8 / normal）
  final packet =
      InterChipPacket(cmd: PacketCommand.normal, payload: cbPayloadBytes);
  print('一层object: $packet');

  // 序列化为字节流，并通过一层解码器复原数据包
  final bytes = interEncoder.encode(packet);
  print('一层encode: $bytes');

  final decodedPacket = interDecoder.decode(bytes)!;
  print('一层decode: $decodedPacket');

  // 解析二层结构
  final decodedCb = cbDecoder.decode(decodedPacket)!;
  print('二层decode: $decodedCb');

  print('');
}

/// 二层协议：DFU 编码与解码示例
///
/// 功能描述：
/// - 使用 DfuMessage 构造二层负载（DfuCmd + DfuVersion + DfuPayload）
/// - 通过 DfuEncoder 生成一层 InterChipPacket 并序列化
/// - 使用 InterChipDecoder + DfuDecoder 反解得到二层结构
void example7() {
  print('');
  print('7. 二层协议：DFU 编码与解码示例');
  print('=' * 100);

  const interEncoder = InterChipEncoder();
  const interDecoder = InterChipDecoder();
  final dfuEncoder = DfuEncoder();
  final dfuDecoder = DfuDecoder();

  // 构造 DFU 二层消息：DfuCmd=0x10，Version=0x01，负载 [0xDE, 0xAD]
  final dfuMsg = DfuMessage(
    dfuCmd: 0x10,
    dfuVersion: 0x01,
    dfuPayload: [0xDE, 0xAD],
  );
  print('二层object: $dfuMsg');

  // 仅编码二层内容（不含一层字段）
  final dfuPayloadBytes = dfuEncoder.encode(dfuMsg);
  print('二层encode: $dfuPayloadBytes');

  // 生成一层数据包（Cmd 固定为 0x20 / dfu）
  final packet =
      InterChipPacket(cmd: PacketCommand.dfu, payload: dfuPayloadBytes);
  print('一层object: $packet');

  // 序列化为字节流，并通过一层解码器复原数据包
  final bytes = interEncoder.encode(packet);
  final decodedPacket = interDecoder.decode(bytes)!;
  print('一层decode: $decodedPacket');

  // 解析二层结构
  final decodedDfu = dfuDecoder.decode(decodedPacket)!;
  print('二层decode: $decodedDfu');

  print('');
}
