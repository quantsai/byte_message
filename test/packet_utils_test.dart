import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';

void main() {
  group('PacketUtils: bytes/int conversions', () {
    test('bytesToInt16 combines low/high (LE)', () {
      expect(PacketUtils.bytesToInt16(0x34, 0x12), equals(0x1234));
    });

    test('bytesToInt16 throws on invalid u8', () {
      expect(() => PacketUtils.bytesToInt16(-1, 0x00), throwsArgumentError);
      expect(() => PacketUtils.bytesToInt16(0x00, 256), throwsArgumentError);
    });

    test('int16ToBytes splits to [low, high] (LE)', () {
      expect(PacketUtils.int16ToBytes(0x1234), equals([0x34, 0x12]));
    });

    test('int16ToBytes throws on invalid u16', () {
      expect(() => PacketUtils.int16ToBytes(-1), throwsArgumentError);
      expect(() => PacketUtils.int16ToBytes(65536), throwsArgumentError);
    });
  });

  group('PacketUtils: XOR checksum', () {
    test('calculateXorChecksum and verify', () {
      final data = [0x01, 0x02, 0x03];
      final checksum = PacketUtils.calculateXorChecksum(data);
      expect(checksum, equals(0x00 ^ 0x01 ^ 0x02 ^ 0x03));
      expect(PacketUtils.verifyXorChecksum(data, checksum), isTrue);
      expect(
          PacketUtils.verifyXorChecksum(data, (checksum + 1) & 0xFF), isFalse);
    });

    test('calculateXorChecksum throws on invalid byte', () {
      expect(
          () => PacketUtils.calculateXorChecksum([256]), throwsArgumentError);
    });
  });

  group('PacketUtils: validations', () {
    test('isValidPayloadLength', () {
      expect(PacketUtils.isValidPayloadLength(0), isTrue);
      expect(PacketUtils.isValidPayloadLength(PacketConstants.MAX_PAYLOAD_LONG),
          isTrue);
      expect(PacketUtils.isValidPayloadLength(-1), isFalse);
      expect(
          PacketUtils.isValidPayloadLength(
              PacketConstants.MAX_PAYLOAD_LONG + 1),
          isFalse);
    });

    test('isResponseCommand (based on InterChipCmds.fromValue)', () {
      expect(PacketUtils.isResponseCommand(InterChipCmds.ackOk.value), isTrue);
      expect(PacketUtils.isResponseCommand(0xEE), isFalse);
    });

    test('isCommandProtocol / isDfuProtocol', () {
      expect(PacketUtils.isCommandProtocol(PacketConstants.CMD_CONTROL_BUS),
          isTrue);
      expect(PacketUtils.isCommandProtocol(PacketConstants.CMD_DFU), isFalse);
      expect(PacketUtils.isDfuProtocol(PacketConstants.CMD_DFU), isTrue);
      expect(
          PacketUtils.isDfuProtocol(PacketConstants.CMD_CONTROL_BUS), isFalse);
    });

    test('isValidLength short and long', () {
      // short frame
      expect(PacketUtils.isValidLength(3, null, 3), isTrue);
      expect(PacketUtils.isValidLength(3, null, 4), isFalse);

      // long frame: len=0x34, lenH=0x12 => 0x1234=4660
      expect(PacketUtils.isValidLength(0x34, 0x12, 0x1234), isTrue);
      expect(PacketUtils.isValidLength(0x34, 0x12, 0x1235), isFalse);

      // invalid u8 should be false
      expect(PacketUtils.isValidLength(-1, null, 0), isFalse);
      expect(PacketUtils.isValidLength(0, 256, 0), isFalse);
    });

    test('isValidCommand and isValidPayload', () {
      expect(PacketUtils.isValidCommand(0), isTrue);
      expect(PacketUtils.isValidCommand(255), isTrue);
      expect(PacketUtils.isValidCommand(-1), isFalse);
      expect(PacketUtils.isValidCommand(256), isFalse);

      expect(PacketUtils.isValidPayload([0, 1, 2, 255]), isTrue);
      expect(PacketUtils.isValidPayload([0, -1]), isFalse);
    });
  });

  group('PacketUtils: analyze/format/parse/debug', () {
    test('analyzePacket handles empty and short inputs', () {
      final empty = PacketUtils.analyzePacket(const []);
      expect(empty['error'], isNotNull);

      final short = PacketUtils.analyzePacket(const [0x50]);
      expect(short['error'], isNotNull);
    });

    test('analyzePacket with long+checksum frame computes fields', () {
      // 构造一个长帧 + 校验和 数据：Flag(0x50) | Len(0x03) | LenH(0x00) | Cmd(0xF8) | Payload(2字节) | Checksum(占位)
      final flag = PacketConstants.FLAG_LONG_CHECKSUM; // 0x50
      final len = 0x03; // totalLength (Cmd+Payload)
      final lenH = 0x00;
      final cmd = InterChipCmds.normal.value;
      final payload = [0xAA, 0xBB];
      final withoutChecksum = [flag, len, lenH, cmd, ...payload];
      final checksum = PacketUtils.calculateXorChecksum(withoutChecksum);
      final data = [...withoutChecksum, checksum];

      final info = PacketUtils.analyzePacket(data);
      expect(info['flag'], equals('0x50'));
      expect(info['len'], equals(len));
      expect(info['lenH'], equals(lenH));
      expect(info['totalLength'], equals(0x0003));
      expect(
          info['expectedPacketLength'],
          equals(PacketConstants.calculateMinPacketLength(
                  longFrame: true, checksumEnabled: true) +
              0x0003 -
              1));
      expect(info['actualPacketLength'], equals(data.length));
      expect(info['lengthMatch'], isTrue);
    });

    test('formatBytes and parseHexString round-trip', () {
      final bytes = [0x01, 0xAB, 0xCD, 0x00];
      final hex = PacketUtils.formatBytes(bytes);
      expect(hex, equals('0x01 0xab 0xcd 0x00'));

      final parsed = PacketUtils.parseHexString('0x01  AB-cd:00');
      expect(parsed, equals([0x01, 0xAB, 0xCD, 0x00]));
    });

    test('parseHexString error cases', () {
      expect(() => PacketUtils.parseHexString(''), throwsArgumentError);
      expect(() => PacketUtils.parseHexString('GG'), throwsArgumentError);
      expect(() => PacketUtils.parseHexString('0x1'),
          throwsArgumentError); // odd length
    });

    test('generateDebugInfo contains key fields', () {
      final data = [
        PacketConstants.FLAG_CHECKSUM,
        0x03,
        InterChipCmds.normal.value,
        0x01,
        0x02,
        0x00
      ];
      final info = PacketUtils.generateDebugInfo(data);
      expect(info.contains('Packet Debug Info'), isTrue);
      expect(info.contains('Raw data:'), isTrue);
      expect(info.contains('Length:'), isTrue);
    });
  });
}
