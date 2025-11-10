import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';

void main() {
  group('L3 SetJoystick', () {
    test('encode s16 BE sequence for boundary values', () {
      final req = SetJoystickReq(x: 100, y: -100, z: 0);
      final bytes = req.encode();
      expect(bytes.length, equals(6));

      // 期望：X=100 -> 0x00 0x64；Y=-100 -> 0xFF 0x9C；Z=0 -> 0x00 0x00
      expect(bytes.sublist(0, 2), equals([0x00, 0x64]));
      expect(bytes.sublist(2, 4), equals([0xFF, 0x9C]));
      expect(bytes.sublist(4, 6), equals([0x00, 0x00]));

      // 交叉验证：使用 ByteData 解码为 s16 BE
      final b = ByteData(6);
      for (int i = 0; i < 6; i++) {
        b.setUint8(i, bytes[i]);
      }
      expect(b.getInt16(0, Endian.big), equals(100));
      expect(b.getInt16(2, Endian.big), equals(-100));
      expect(b.getInt16(4, Endian.big), equals(0));
    });

    test('encode throws RangeError for out-of-range axis', () {
      expect(() => SetJoystickReq(x: -101, y: 0, z: 0).encode(), throwsRangeError);
      expect(() => SetJoystickReq(x: 0, y: 101, z: 0).encode(), throwsRangeError);
      expect(() => SetJoystickReq(x: 0, y: 0, z: -101).encode(), throwsRangeError);
    });
  });

  group('L3 SetOperatingMode', () {
    test('encode single u8 mode value', () {
      final req = SetOperatingModeReq(mode: OperatingMode.selfBalance);
      final bytes = req.encode();
      expect(bytes, equals([OperatingMode.selfBalance.value & 0xFF]));
    });
  });

  group('L3 SetSpeedGear', () {
    test('encode single u8 gear value', () {
      final req = SetSpeedGearReq(gear: SpeedGear.gear3);
      final bytes = req.encode();
      expect(bytes, equals([SpeedGear.gear3.value & 0xFF]));
    });
  });

  group('L3 SetPushRodSpeed', () {
    test('encode 4 x f32 BE (int-based packing) to 16 bytes', () {
      final req = SetPushRodSpeedReq(
        speedA: 1.5,
        speedB: -2.25,
        speedC: 0.0,
        speedD: 100.0,
      );
      final bytes = req.encode();
      expect(bytes.length, equals(16));
      // 当前实现采用整数部分打包（参见 byte_packing.packF32BE），验证每段为 value.toInt 的 BE 表示。
      // A=1 -> 0x00 0x00 0x00 0x01
      expect(bytes.sublist(0, 4), equals([0x00, 0x00, 0x00, 0x01]));
      // B=-2 -> 0xFF 0xFF 0xFF 0xFE
      expect(bytes.sublist(4, 8), equals([0xFF, 0xFF, 0xFF, 0xFE]));
      // C=0 -> 0x00 0x00 0x00 0x00
      expect(bytes.sublist(8, 12), equals([0x00, 0x00, 0x00, 0x00]));
      // D=100 -> 0x00 0x00 0x00 0x64
      expect(bytes.sublist(12, 16), equals([0x00, 0x00, 0x00, 0x64]));
    });

    test('SetPushRodSpeedAck.fromBytes throws for non-empty payload', () {
      expect(() => SetPushRodSpeedAck.fromBytes(const [0x00]), throwsArgumentError);
    });
  });
}