import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';
import 'package:byte_message/src/utils/byte_packing.dart';

void main() {
  group('Layer3 Control Bus: Battery Status', () {
    test('fromBytes parses percent and status: charging', () {
      final res = GetBatteryStatusRes.fromBytes(const [50, 0x01]);
      expect(res.batteryPercent, 50);
      expect(res.chargeStatus, ChargeStatus.charging);
    });

    test(
        'fromBytes parses status: chargeComplete when percent=100 and status=0',
        () {
      final res = GetBatteryStatusRes.fromBytes(const [100, 0x00]);
      expect(res.batteryPercent, 100);
      expect(res.chargeStatus, ChargeStatus.chargeComplete);
    });

    test('fromBytes parses status: notCharging when percent<100 and status=0',
        () {
      final res = GetBatteryStatusRes.fromBytes(const [20, 0x00]);
      expect(res.batteryPercent, 20);
      expect(res.chargeStatus, ChargeStatus.notCharging);
    });
  });

  group('Layer3 Control Bus: Operating Mode', () {
    test('fromBytes with valid enum value', () {
      final validValue = OperatingMode.values.first.value;
      final res = GetOperatingModeRes.fromBytes([validValue]);
      expect(res.mode.value, equals(validValue));
    });

    // 负例：长度不为 1 应抛出 ArgumentError
    test('fromBytes throws for invalid payload length (0 or >1)', () {
      expect(
          () => GetOperatingModeRes.fromBytes(const []), throwsArgumentError);
      expect(() => GetOperatingModeRes.fromBytes(const [0x00, 0x01]),
          throwsArgumentError);
    });

    // 负例：非法模式值（非 0x00/0x01）应抛出 ArgumentError
    test('fromBytes throws for invalid operating mode value 0xFF', () {
      expect(() => GetOperatingModeRes.fromBytes(const [0xFF]),
          throwsArgumentError);
    });
  });

  group('Layer3 Control Bus: Electrical Metrics (negatives)', () {
    // 负例：长度不足 8 字节应抛出 ArgumentError
    test('fromBytes throws for invalid payload length (<8 bytes)', () {
      for (final len in [0, 1, 2, 3, 4, 5, 6, 7]) {
        expect(
          () => GetElectricalMetricsRes.fromBytes(List<int>.filled(len, 0x00)),
          throwsArgumentError,
          reason: 'len=$len should throw',
        );
      }
    });
  });

  group('Layer3 Control Bus: Device Connection', () {
    test('fromBytes parses model/versions/serial', () {
      // 模型名（12字节 ASCII，以空格或0x00填充）
      final modelBytes = 'MODEL-000001'.codeUnits; // 恰好12字节

      // 固件/硬件版本（u16 BE）
      final fw = packU16BE(0x0102);
      final hw = packU16BE(0x0304);

      // 序列号分段（3个 u32 BE）
      final snSeg0 = packU32BE(0x00010002);
      final snSeg1 = packU32BE(0x00030004);
      final snSeg2 = packU32BE(0x00050006);

      final bytes = <int>[
        ...modelBytes,
        ...fw,
        ...hw,
        ...snSeg0,
        ...snSeg1,
        ...snSeg2,
      ];

      final res = GetDeviceConnectionRes.fromBytes(bytes);
      expect(res.model, equals('MODEL-000001'));
      expect(res.firmwareVersion, equals('0x0102'));
      expect(res.hardwareVersion, equals('0x0304'));
      expect(res.serialNumber, equals('00010002-00030004-00050006'));
    });
  });

  group('Layer3 Control Bus: SetJoystick range', () {
    test('encode throws RangeError for out-of-range axis', () {
      final req = SetJoystickReq(x: 0, y: 0, z: 101); // z 超界
      expect(() => req.encode(), throwsRangeError);
    });
  });
}
