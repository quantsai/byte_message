import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';
// 设备语言未在公共出口中导出，测试使用内部模块路径
import 'package:byte_message/src/protocols/layer3/control_bus/get_device_language.dart';
// 字节打包工具未在公共出口中导出，测试使用内部模块路径
import 'package:byte_message/src/utils/byte_packing.dart';
// 枚举命令未在公共出口中导出，测试使用内部模块路径
import 'package:byte_message/src/models/layer2/control_bus_cmd.dart';

void main() {
  group('L3 SetSpeed (speed_control)', () {
    test('SetSpeedReq.encode packs two f32 BE (int-based)', () {
      final req = SetSpeedReq(linearVelocity: 2.75, angularVelocity: -1.5);
      final bytes = req.encode();
      expect(bytes.length, 8);
      // 当前实现按 value.toInt 的 BE 方式打包
      expect(bytes.sublist(0, 4), equals([0x00, 0x00, 0x00, 0x02]));
      expect(bytes.sublist(4, 8), equals([0xFF, 0xFF, 0xFF, 0xFF & -1]));
    });

    test('SetSpeedAck.fromBytes throws for non-empty payload', () {
      expect(() => SetSpeedAck.fromBytes(const [0x00]), throwsArgumentError);
    });

    test('SetSpeedAck.fromBytes succeeds for empty payload', () {
      final ack = SetSpeedAck.fromBytes(const []);
      expect(ack, isA<SetSpeedAck>());
    });
  });

  group('L3 SetFoldState', () {
    test('FoldState.fromValue valid values (0x00, 0x01)', () {
      expect(FoldState.fromValue(0x00), equals(FoldState.fold));
      expect(FoldState.fromValue(0x01), equals(FoldState.unfold));
    });

    test('FoldState.fromValue invalid throws ArgumentError', () {
      expect(() => FoldState.fromValue(0xFF), throwsArgumentError);
    });

    test('SetFoldStateReq.encode produces single u8', () {
      final req = SetFoldStateReq(state: FoldState.unfold);
      expect(req.encode(), equals([0x01]));
    });
  });

  group('Layer2 ControlBusMessage', () {
    test('fromBytes returns null for empty input', () {
      expect(ControlBusMessage.fromBytes(const []), isNull);
    });

    test('fromBytes parses cbCmd and cbPayload slice', () {
      final msg = ControlBusMessage.fromBytes(const [0x36, 0xAA, 0xBB]);
      expect(msg, isNotNull);
      expect(msg!.cbCmd, CbCmd.electricalMetricsRequest);
      expect(msg.cbPayload, equals([0xAA, 0xBB]));
    });

    test('== and hashCode for identical payload', () {
      final a = ControlBusMessage(
          cbCmd: CbCmd.speedControlRequest, cbPayload: const [1, 2]);
      final b = ControlBusMessage(
          cbCmd: CbCmd.speedControlRequest, cbPayload: const [1, 2]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString contains hex-formatted cbCmd', () {
      final msg = ControlBusMessage(
          cbCmd: CbCmd.foldControlRequest, cbPayload: const [0x00]);
      expect(msg.toString().contains('0x82'), isTrue);
    });
  });

  group('Utils byte_packing', () {
    test('composeVersion and formatVersionU16 round-trip', () {
      final v = composeVersion(major: 1, minor: 2, revision: 3);
      expect(v, equals((1 << 8) | (2 << 4) | 3));
      expect(formatVersionU16(v), equals('1.2.3'));
    });

    test('packU16BE boundaries', () {
      expect(packU16BE(0), equals([0x00, 0x00]));
      expect(packU16BE(65535), equals([0xFF, 0xFF]));
    });

    test('readU16BE and readU32BE with BE arrays', () {
      expect(readU16BE(const [0x12, 0x34]), equals(0x1234));
      expect(readU32BE(const [0x00, 0x00, 0x01, 0x00]), equals(256));
    });

    test('packS16BE and packS32BE handle negatives and positives', () {
      expect(packS16BE(-1), equals([0xFF, 0xFF]));
      expect(packS16BE(32767), equals([0x7F, 0xFF]));
      expect(packS32BE(-2), equals([0xFF, 0xFF, 0xFF, 0xFE]));
    });

    test('packU32BE boundaries', () {
      expect(packU32BE(0), equals([0x00, 0x00, 0x00, 0x00]));
      expect(packU32BE(0x7FFFFFFF), equals([0x7F, 0xFF, 0xFF, 0xFF]));
    });

    test('packF16BE and packF32BE follow int-based packing', () {
      expect(packF16BE(258.9), equals([0x01, 0x02]));
      expect(packF32BE(1.5), equals([0x00, 0x00, 0x00, 0x01]));
      expect(packF32BE(-2.0), equals([0xFF, 0xFF, 0xFF, 0xFE]));
    });

    test('padDecimalLeft formats fixed width string', () {
      expect(padDecimalLeft(123, width: 6), equals('000123'));
      expect(padDecimalLeft(0, width: 4, padChar: 'X'), equals('XXX0'));
    });
  });

  group('DFU FinishUpgrade', () {
    test('FinishUpgradeReq.encode returns empty payload', () {
      expect(FinishUpgradeReq().encode(), isEmpty);
    });

    test('FinishUpgradeRes.fromBytes parses version and result', () {
      final res = FinishUpgradeRes.fromBytes(const [0x01, 0x00]);
      expect(res.dfuPkgVersion, 1);
      expect(res.dfuOpResult, 0x00);
      expect(res.toString().contains('dfuOpResult'), isTrue);
    });

    test('FinishUpgradeRes.fromBytes throws on invalid length', () {
      expect(
          () => FinishUpgradeRes.fromBytes(const [0x01]), throwsArgumentError);
      expect(() => FinishUpgradeRes.fromBytes(const [0x01, 0x00, 0x02]),
          throwsArgumentError);
    });
  });

  group('L1 InterChipDecoder more branches', () {
    final decoder = InterChipDecoder();

    test('isValidPacketFormat false cases: empty and short len', () {
      expect(decoder.isValidPacketFormat(const []), isFalse);
      // flag=0x40(short+checksum)，但长度字段缺失
      expect(decoder.isValidPacketFormat(const [PacketConstants.FLAG_CHECKSUM]),
          isFalse);
    });

    test('calculateExpectedLength short and long frames', () {
      // short frame: flag checksum, len=2, cmd+payload(1)
      final shortExpected = decoder.calculateExpectedLength([
        PacketConstants.FLAG_CHECKSUM,
        0x02,
        InterChipCmds.normal.value,
        0x00
      ]);
      expect(shortExpected, equals(1 + 1 + 2 + 1));

      // long frame: len=0x03, lenH=0x00, cmd+payload(2) + checksum
      final longExpected = decoder.calculateExpectedLength([
        PacketConstants.FLAG_LONG_CHECKSUM,
        0x03,
        0x00,
        InterChipCmds.normal.value,
        0xAA,
        0xBB,
        0x00
      ]);
      expect(longExpected, equals(1 + 2 + 0x03 + 1));
    });

    test('decodeMultiple parses consecutive packets', () {
      // 构造两个短帧（带校验和）
      List<int> makeShort(List<int> payload) {
        final base = [
          PacketConstants.FLAG_CHECKSUM,
          1 + payload.length,
          InterChipCmds.normal.value,
          ...payload
        ];
        final cs = PacketUtils.calculateXorChecksum(base);
        return [...base, cs];
      }

      final stream = [
        ...makeShort([0x11]),
        ...makeShort([0x22, 0x33])
      ];
      final packets = decoder.decodeMultiple(stream);
      expect(packets.length, 2);
      expect(packets[0].payload, equals([0x11]));
      expect(packets[1].payload, equals([0x22, 0x33]));
    });

    test('validatePacketIntegrity with checksum-enabled packet', () {
      final base = [
        PacketConstants.FLAG_CHECKSUM,
        0x02,
        InterChipCmds.normal.value,
        0xAA
      ];
      final cs = PacketUtils.calculateXorChecksum(base);
      final pkt = InterChipPacket(
        flag: base[0],
        len: base[1],
        cmd: InterChipCmds.normal,
        payload: const [0xAA],
        checksum: cs,
      );
      expect(decoder.validatePacketIntegrity(pkt), isTrue);
    });
  });

  group('L3 GetElectricalMetrics positive parsing', () {
    test('fromBytes parses s32-like values (using readU32BE)', () {
      final res = GetElectricalMetricsRes.fromBytes(const [
        0x00, 0x00, 0x01, 0x00, // 256 mV
        0x00, 0x00, 0x00, 0x64, // 100 mA
      ]);
      expect(res.voltageMv, 256);
      expect(res.currentMa, 100);
    });
  });

  group('L3 GetDeviceLanguage additional', () {
    test('GetDeviceLanguageReq.encode is empty', () {
      expect(GetDeviceLanguageReq().encode(), isEmpty);
    });

    test('GetDeviceLanguageRes.fromBytes valid values', () {
      final zh = GetDeviceLanguageRes.fromBytes(const [0x01]);
      final en = GetDeviceLanguageRes.fromBytes(const [0x02]);
      expect(zh.language, DeviceLanguage.chinese);
      expect(en.language, DeviceLanguage.english);
      expect(zh.toString().contains('0x1'), isTrue);
    });

    test('GetDeviceLanguageRes.fromBytes throws for invalid code/len', () {
      expect(
          () => GetDeviceLanguageRes.fromBytes(const []), throwsArgumentError);
      expect(() => GetDeviceLanguageRes.fromBytes(const [0xEE]),
          throwsArgumentError);
      expect(() => GetDeviceLanguageRes.fromBytes(const [0x01, 0x00]),
          throwsArgumentError);
    });
  });
}
