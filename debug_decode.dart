import 'lib/byte_message.dart';

void main() {
  print('=== 解码问题调试 ===');

  // 创建编码器和解码器
  const encoder = InterChipEncoder();
  // 创建解码器（启用调试模式）
  const decoder = InterChipDecoder(config: DecoderConfig(debugMode: true));

  // 创建测试数据包
  final packet = InterChipPacket(
    cmd: PacketCommand.normal,
    payload: [0x01, 0x02, 0x03],
  );

  print('原始数据包:');
  print('  cmd: ${packet.cmd}');
  print('  payload: ${packet.payload}');
  print('  flags: ${packet.flags}');
  print('  checksum: ${packet.checksum}');

  // 编码
  final encodedData = encoder.encode(packet);
  print('\n编码结果:');
  print('  长度: ${encodedData.length}');
  print(
    '  数据: ${encodedData.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(' ')}',
  );

  // 分析编码数据的结构
  print('\n编码数据分析:');
  PacketFlags? flags;
  if (encodedData.isNotEmpty) {
    print(
      '  Flag: 0x${encodedData[0].toRadixString(16).padLeft(2, '0').toUpperCase()}',
    );
    flags = PacketFlags.fromFlag(encodedData[0]);
    print('    isLongFrame: ${flags.isLongFrame}');
    print('    checksumEnable: ${flags.checksumEnable}');
  }

  if (encodedData.length > 1) {
    print('  Len: ${encodedData[1]}');
  }

  if (encodedData.length > 2) {
    print(
      '  Cmd: 0x${encodedData[2].toRadixString(16).padLeft(2, '0').toUpperCase()}',
    );
  }

  if (encodedData.length > 3 && flags != null) {
    print(
      '  Payload: ${encodedData.sublist(3, encodedData.length - (flags.checksumEnable ? 1 : 0))}',
    );
  }

  if (flags?.checksumEnable == true && encodedData.isNotEmpty) {
    print(
      '  Checksum: 0x${encodedData.last.toRadixString(16).padLeft(2, '0').toUpperCase()}',
    );
  }

  // 格式验证
  print('\n格式验证:');
  print('  isValidPacketFormat: ${decoder.isValidPacketFormat(encodedData)}');
  print(
    '  calculateExpectedLength: ${decoder.calculateExpectedLength(encodedData)}',
  );
  print('  实际长度: ${encodedData.length}');

  // 解码尝试
  print('\n解码尝试:');
  try {
    final decodedPacket = decoder.decode(encodedData);
    if (decodedPacket != null) {
      print('  解码成功!');
      print('    cmd: ${decodedPacket.cmd}');
      print('    payload: ${decodedPacket.payload}');
      print('    flags: ${decodedPacket.flags}');
      print('    checksum: ${decodedPacket.checksum}');
    } else {
      print('  解码失败 - 返回null');
    }
  } catch (e) {
    print('  解码异常: $e');
  }

  final tryDecodeResult = decoder.tryDecode(encodedData);
  print('  tryDecode结果:');
  print('    success: ${tryDecodeResult.success}');
  print('    needMoreData: ${tryDecodeResult.needMoreData}');
  print('    error: ${tryDecodeResult.error}');
  print('    errorCode: ${tryDecodeResult.errorCode}');
}
