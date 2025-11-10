import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';

/// 构造一个标准帧的 InterChipPacket，便于重复使用的测试辅助函数。
///
/// 参数：
/// - [cmd] 第一层命令（InterChipCmds）。
/// - [payload] 负载字节数组（List<int>）。
/// 返回：
/// - [InterChipPacket] 用于编码的包对象（不显式提供 flag/len/lenH/checksum，让编码器自动计算）。
InterChipPacket buildStandardPacket(InterChipCmds cmd, List<int> payload) {
  return InterChipPacket(cmd: cmd, payload: payload);
}

void main() {
  group('Layer1 InterChipEncoder/Decoder', () {
    test('encode standard frame with checksum and decode back', () {
      final packet =
          buildStandardPacket(InterChipCmds.normal, const [0x01, 0x02]);
      final encoder = InterChipEncoder();

      final bytes = encoder.encode(packet);

      // 结构：Flag | Len | Cmd | Payload | Checksum
      expect(bytes.length,
          1 /*flag*/ + 1 /*len*/ + 1 /*cmd*/ + 2 /*payload*/ + 1 /*checksum*/);

      // Flag 校验：启用校验和但非长帧
      final flag = bytes[0];
      expect((flag & PacketConstants.FLAG_MASK_CHECKSUM_ENABLE) != 0, isTrue);
      expect((flag & PacketConstants.FLAG_LONG) == 0, isTrue);

      // 长度字段应为 cmd(1) + payload(2) = 3
      expect(bytes[1], equals(3));
      expect(bytes[2], equals(InterChipCmds.normal.value));

      // 校验和验证
      final dataForChecksum = bytes.sublist(0, bytes.length - 1);
      final checksumByte = bytes.last;
      expect(
          PacketUtils.verifyXorChecksum(dataForChecksum, checksumByte), isTrue);

      // 解码验证
      final decoder = InterChipDecoder();
      final decoded = decoder.decode(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.cmd, InterChipCmds.normal);
      expect(decoded.payload, equals(const [0x01, 0x02]));
      expect(decoded.checksum, isNotNull);
      expect(decoded.flags!.checksumEnable, isTrue);
      expect(decoded.flags!.isLongFrame, isFalse);
      expect(decoded.len, equals(3));
      expect(decoded.lenH, isNull);
    });

    test(
        'encode long frame when payload > max standard payload and decode back',
        () {
      // 构造超出标准帧限制的 payload（> 254）
      final payload = List<int>.generate(260, (i) => i & 0xFF);
      final packet = buildStandardPacket(InterChipCmds.normal, payload);
      final encoder = InterChipEncoder();
      final bytes = encoder.encode(packet);

      // 长帧：Flag 应包含 LONG 位且启用校验和
      final flag = bytes[0];
      expect((flag & PacketConstants.FLAG_LONG) != 0, isTrue);
      expect((flag & PacketConstants.FLAG_MASK_CHECKSUM_ENABLE) != 0, isTrue);

      // 长度字段：两字节（低位在前，高位在后），应为 cmd(1) + payload(260) = 261
      final lenL = bytes[1];
      final lenH = bytes[2];
      final totalLen = PacketUtils.bytesToInt16(lenL, lenH);
      expect(totalLen, equals(1 + payload.length));

      // cmd 字节位置与值
      expect(bytes[3], equals(InterChipCmds.normal.value));

      // 解码并比对负载长度
      final decoder = InterChipDecoder();
      final decoded = decoder.decode(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.flags!.isLongFrame, isTrue);
      expect(decoded.len, equals(lenL));
      expect(decoded.lenH, equals(lenH));
      expect(decoded.payload.length, equals(payload.length));
      expect(
          decoded.payload.sublist(0, 5), equals(payload.sublist(0, 5))); // 采样比对
    });

    test('decode returns null on checksum mismatch', () {
      final packet =
          buildStandardPacket(InterChipCmds.normal, const [0x0A, 0x0B, 0x0C]);
      final encoder = InterChipEncoder();
      final bytes = encoder.encode(packet);

      // 篡改校验和
      final corrupted = List<int>.from(bytes);
      corrupted[corrupted.length - 1] = (corrupted.last + 1) & 0xFF;

      final decoder = InterChipDecoder();
      final decoded = decoder.decode(corrupted);
      expect(decoded, isNull);
    });
  });

  group('Layer1 InterChip models helpers', () {
    test('InterChipFlags encode/decode', () {
      final flags = InterChipFlags(isLongFrame: true, checksumEnable: true);
      final flagByte = flags.encode();
      expect(PacketConstants.isLongFrameEnabled(flagByte), isTrue);
      expect(PacketConstants.isChecksumEnabled(flagByte), isTrue);

      final decoded = InterChipFlags.decode(flagByte);
      expect(decoded, equals(flags));
    });

    test('InterChipPacket totalPayloadLength with len/lenH', () {
      // 长帧：lenH存在时 totalPayloadLength = bytesToInt16(len, lenH)
      final pktLong = InterChipPacket(
        flag: PacketConstants.FLAG_LONG_CHECKSUM,
        len: 0x34,
        lenH: 0x12,
        cmd: InterChipCmds.normal,
        payload: const [0xAA],
        checksum: 0x00,
      );
      expect(pktLong.totalPayloadLength,
          equals(PacketUtils.bytesToInt16(0x34, 0x12)));

      // 短帧：len存在且无lenH时 totalPayloadLength = len
      final pktShort = InterChipPacket(
        flag: PacketConstants.FLAG_CHECKSUM,
        len: 0x03,
        cmd: InterChipCmds.normal,
        payload: const [0xAA, 0xBB],
        checksum: 0x00,
      );
      expect(pktShort.totalPayloadLength, equals(0x03));

      // 未提供len：返回 payload.length + 1（含cmd）
      final pktNoLen = InterChipPacket(
        cmd: InterChipCmds.normal,
        payload: const [0xAA, 0xBB, 0xCC],
      );
      expect(pktNoLen.totalPayloadLength, equals(4));
    });

    test('InterChipPacket field validation throws on invalid payload byte', () {
      expect(
        () => InterChipPacket(cmd: InterChipCmds.normal, payload: const [256]),
        throwsArgumentError,
      );
    });
  });
}
