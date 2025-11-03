import 'package:test/test.dart';
import 'package:byte_message/src/models/packet_models.dart';
import 'package:byte_message/src/models/packet_command.dart';
import 'package:byte_message/src/constants/packet_constants.dart';

/// 数据包模型测试
///
/// 测试InterChipPacket和PacketFlags的功能
void main() {
  group('PacketFlags 测试', () {
    test('构造函数', () {
      final flags = PacketFlags(isLongFrame: false, checksumEnable: false);
      expect(flags.isLongFrame, false);
      expect(flags.checksumEnable, false);
      expect(flags.toFlag(), 0x00);
    });

    test('从标志位构造', () {
      final flags = PacketFlags.fromFlag(0x50);
      expect(flags.isLongFrame, true);
      expect(flags.checksumEnable, true);
    });

    test('标志位转换', () {
      final flags = PacketFlags(isLongFrame: true, checksumEnable: false);
      expect(flags.toFlag(), 0x40);
    });

    test('所有标志位组合', () {
      // 无标志位
      expect(
        PacketFlags(isLongFrame: false, checksumEnable: false).toFlag(),
        0x00,
      );
      // 仅校验和
      expect(
        PacketFlags(isLongFrame: false, checksumEnable: true).toFlag(),
        0x10,
      );
      // 仅长帧
      expect(
        PacketFlags(isLongFrame: true, checksumEnable: false).toFlag(),
        0x40,
      );
      // 长帧+校验和
      expect(
        PacketFlags(isLongFrame: true, checksumEnable: true).toFlag(),
        0x50,
      );
    });
  });

  group('InterChipPacket 测试', () {
    test('基础数据包创建', () {
      final packet = InterChipPacket(
        flag: 0x10,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
        checksum: 0xAB,
      );

      expect(packet.flag, 0x10);
      expect(packet.len, 4);
      expect(packet.lenH, null);
      expect(packet.cmd, PacketCommand.normal);
      expect(packet.payload, [0x01, 0x02, 0x03]);
      expect(packet.checksum, 0xAB);
    });

    test('长帧数据包创建', () {
      final packet = InterChipPacket(
        flag: 0x50,
        len: 0x2D,
        lenH: 0x01,
        cmd: PacketCommand.dfu,
        payload: List.generate(300, (i) => i % 256),
        checksum: 0xCD,
      );

      expect(packet.flag, 0x50);
      expect(packet.len, 0x2D);
      expect(packet.lenH, 0x01);
      expect(packet.cmd, PacketCommand.dfu);
      expect(packet.payload.length, 300);
      expect(packet.checksum, 0xCD);
    });

    test('标志位解析', () {
      final packet = InterChipPacket(
        flag: 0x50,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final flags = packet.flags;
      expect(flags?.isLongFrame, true);
      expect(flags?.checksumEnable, true);
    });

    test('总负载长度计算 - 短帧', () {
      final packet = InterChipPacket(
        flag: 0x10,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      expect(packet.totalPayloadLength, 4);
    });

    test('总负载长度计算 - 长帧', () {
      final packet = InterChipPacket(
        flag: 0x50,
        len: 0x2D, // 45
        lenH: 0x01, // 1
        cmd: PacketCommand.dfu,
        payload: List.generate(300, (i) => i % 256),
      );

      // 小端序: len + (lenH << 8) = 45 + (1 << 8) = 45 + 256 = 301
      expect(packet.totalPayloadLength, 301);
    });

    test('数据包相等性比较', () {
      final packet1 = InterChipPacket(
        flag: 0x10,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
        checksum: 0xAB,
      );

      final packet2 = InterChipPacket(
        flag: 0x10,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
        checksum: 0xAB,
      );

      expect(packet1, equals(packet2));
      expect(packet1.hashCode, equals(packet2.hashCode));
    });

    test('数据包字符串表示', () {
      final packet = InterChipPacket(
        flag: 0x10,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
        checksum: 0xAB,
      );

      final str = packet.toString();
      expect(str, contains('InterChipPacket'));
      expect(str, contains('flag: 0x10'));
      expect(str, contains('len: 4'));
      expect(str, contains('cmd: 0xf8'));
      expect(str, contains('payload: [0x01, 0x02, 0x03]'));
      expect(str, contains('checksum: 0xab'));
    });

    test('可选字段处理', () {
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      expect(packet.flag, null);
      expect(packet.len, null);
      expect(packet.lenH, null);
      expect(packet.checksum, null);
      expect(packet.cmd, PacketCommand.normal);
      expect(packet.payload, [0x01, 0x02, 0x03]);
    });
  });

  group('PacketCommand 测试', () {
    test('命令枚举值', () {
      expect(PacketCommand.normal.value, PacketConstants.CMD_CONTROL_BUS);
      expect(PacketCommand.dfu.value, PacketConstants.CMD_DFU);
    });

    test('命令字符串表示', () {
      expect(PacketCommand.normal.toString(), 'PacketCommand.normal(0xf8)');
      expect(PacketCommand.dfu.toString(), 'PacketCommand.dfu(0x20)');
    });
  });
}
