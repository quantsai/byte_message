import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';
// 直接引用 src 以测试未导出的常量文件
import 'package:byte_message/src/models/layer2/control_bus_cmd.dart';
import 'package:byte_message/src/models/layer2/dfu_cmd.dart';

void main() {
  group('Constants: ControlBus CbCmd values', () {
    test('CbCmd constant mapping equals spec', () {
      expect(CbCmd.connectionRequest, equals(0x10));
      expect(CbCmd.batteryStatusRequest, equals(0x30));
      expect(CbCmd.electricalMetricsRequest, equals(0x36));
      expect(CbCmd.deviceStatusRequest, equals(0x37));
      expect(CbCmd.operatingModeRequest, equals(0x3D));
      expect(CbCmd.speedGearRequest, equals(0x3E));
      expect(CbCmd.speedControlRequest, equals(0x41));
      expect(CbCmd.pushRodControlRequest, equals(0x42));
      expect(CbCmd.operatingModeControlRequest, equals(0x4D));
      expect(CbCmd.speedGearControlRequest, equals(0x4E));
      expect(CbCmd.joystickControlRequest, equals(0x81));
      expect(CbCmd.foldControlRequest, equals(0x82));
      expect(CbCmd.deviceLanguageControlRequest, equals(0x83));
      expect(CbCmd.muteControlRequest, equals(0x84));
      expect(CbCmd.deviceLanguageRequest, equals(0x85));
      expect(CbCmd.muteStatusRequest, equals(0x86));
    });

    test('CbCmd values are unique', () {
      final values = <int>{
        CbCmd.connectionRequest,
        CbCmd.batteryStatusRequest,
        CbCmd.electricalMetricsRequest,
        CbCmd.deviceStatusRequest,
        CbCmd.operatingModeRequest,
        CbCmd.speedGearRequest,
        CbCmd.speedControlRequest,
        CbCmd.pushRodControlRequest,
        CbCmd.operatingModeControlRequest,
        CbCmd.speedGearControlRequest,
        CbCmd.joystickControlRequest,
        CbCmd.foldControlRequest,
        CbCmd.deviceLanguageControlRequest,
        CbCmd.muteControlRequest,
        CbCmd.deviceLanguageRequest,
        CbCmd.muteStatusRequest,
      };
      expect(values.length, equals(16));
    });
  });

  group('Constants: DFU DfuCmd values', () {
    test('DfuCmd constant mapping equals spec', () {
      expect(DfuCmd.getDeviceInfo, equals(0x01));
      expect(DfuCmd.startUpgrade, equals(0x02));
      expect(DfuCmd.finishUpgrade, equals(0x03));
      expect(DfuCmd.run, equals(0x04));
      expect(DfuCmd.writeUpgradeChunk, equals(0x05));
      expect(DfuCmd.writeUpgradeBulk, equals(0x07));
    });

    test('DfuCmd values are unique', () {
      final values = <int>{
        DfuCmd.getDeviceInfo,
        DfuCmd.startUpgrade,
        DfuCmd.finishUpgrade,
        DfuCmd.run,
        DfuCmd.writeUpgradeChunk,
        DfuCmd.writeUpgradeBulk,
      };
      expect(values.length, equals(6));
    });
  });

  group('Constants: PacketConstants utilities', () {
    test('isLongFrameEnabled and isChecksumEnabled', () {
      expect(PacketConstants.isLongFrameEnabled(0x00), isFalse);
      expect(PacketConstants.isLongFrameEnabled(PacketConstants.FLAG_LONG),
          isTrue);

      expect(PacketConstants.isChecksumEnabled(0x00), isFalse);
      expect(PacketConstants.isChecksumEnabled(PacketConstants.FLAG_CHECKSUM),
          isTrue);
    });

    test('requiresLongFrame and calculateMinPacketLength', () {
      expect(PacketConstants.requiresLongFrame(255), isFalse);
      expect(PacketConstants.requiresLongFrame(256), isTrue);

      // short + checksum
      expect(
        PacketConstants.calculateMinPacketLength(
            longFrame: false, checksumEnabled: true),
        equals(PacketConstants.BASE_HEADER_LENGTH +
            PacketConstants.CHECKSUM_LENGTH),
      );
      // long + checksum
      expect(
        PacketConstants.calculateMinPacketLength(
            longFrame: true, checksumEnabled: true),
        equals(PacketConstants.BASE_HEADER_LENGTH +
            PacketConstants.LONG_FRAME_EXTRA_LENGTH +
            PacketConstants.CHECKSUM_LENGTH),
      );
      // long + no checksum
      expect(
        PacketConstants.calculateMinPacketLength(
            longFrame: true, checksumEnabled: false),
        equals(PacketConstants.BASE_HEADER_LENGTH +
            PacketConstants.LONG_FRAME_EXTRA_LENGTH),
      );
    });
  });

  group('InterChipCmds helpers', () {
    test('fromValue returns known enums', () {
      expect(InterChipCmds.fromValue(0xF8), equals(InterChipCmds.normal));
      expect(InterChipCmds.fromValue(0x20), equals(InterChipCmds.dfu));
      expect(InterChipCmds.fromValue(0x02), equals(InterChipCmds.ackOk));
    });

    test('isValidCommand works and allValues contains expected', () {
      expect(InterChipCmds.isValidCommand(0xF8), isTrue);
      expect(InterChipCmds.isValidCommand(0xEE), isFalse);

      final values = InterChipCmds.allValues;
      expect(values.contains(0xF8), isTrue);
      expect(values.contains(0x20), isTrue);
      expect(values.contains(0x02), isTrue);
    });
  });
}
