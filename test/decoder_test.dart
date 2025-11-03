import 'package:test/test.dart';
import 'package:byte_message/src/decoders/inter_chip_decoder.dart';
import 'package:byte_message/src/models/packet_command.dart';

/// 解码器测试
/// 
/// 测试InterChipDecoder的解码功能
void main() {
  late InterChipDecoder decoder;

  setUp(() {
    decoder = InterChipDecoder();
  });

  group('短帧解码测试', () {
    test('基础短帧解码 - 无校验和', () {
      // Flag(0x00) + Len(4) + Cmd(0xF8) + Payload(3字节)
      final data = [0x00, 0x04, 0xF8, 0x01, 0x02, 0x03];
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.flag, 0x00);
      expect(packet.len, 4);
      expect(packet.lenH, null);
      expect(packet.cmd, PacketCommand.normal);
      expect(packet.payload, [0x01, 0x02, 0x03]);
      expect(packet.checksum, null);
    });

    test('短帧解码 - 有校验和', () {
      // Flag(0x10) + Len(4) + Cmd(0xF8) + Payload(3字节) + Checksum
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03];
      
      // 计算校验和
      int checksum = 0;
      for (int byte in data) {
        checksum ^= byte;
      }
      data.add(checksum);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.flag, 0x10);
      expect(packet.len, 4);
      expect(packet.cmd, PacketCommand.normal);
      expect(packet.payload, [0x01, 0x02, 0x03]);
      expect(packet.checksum, checksum);
    });

    test('空负载短帧解码', () {
      // Flag(0x00) + Len(1) + Cmd(0xF8)
      final data = [0x00, 0x01, 0xF8];
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.len, 1);
      expect(packet.cmd, PacketCommand.normal);
      expect(packet.payload, isEmpty);
    });
  });

  group('长帧解码测试', () {
    test('基础长帧解码 - 无校验和', () {
      final payload = List.generate(300, (i) => i % 256);
      // Flag(0x40) + Len(0x2D) + LenH(0x01) + Cmd(0x20) + Payload(300字节)
      final data = [0x40, 0x2D, 0x01, 0x20];
      data.addAll(payload);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.flag, 0x40);
      expect(packet.len, 0x2D);
      expect(packet.lenH, 0x01);
      expect(packet.cmd, PacketCommand.dfu);
      expect(packet.payload, payload);
      expect(packet.checksum, null);
    });

    test('长帧解码 - 有校验和', () {
      final payload = List.generate(300, (i) => i % 256);
      // Flag(0x50) + Len(0x2D) + LenH(0x01) + Cmd(0x20) + Payload(300字节)
      final data = [0x50, 0x2D, 0x01, 0x20];
      data.addAll(payload);
      
      // 计算校验和
      int checksum = 0;
      for (int byte in data) {
        checksum ^= byte;
      }
      data.add(checksum);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.flag, 0x50);
      expect(packet.len, 0x2D);
      expect(packet.lenH, 0x01);
      expect(packet.cmd, PacketCommand.dfu);
      expect(packet.payload, payload);
      expect(packet.checksum, checksum);
    });

    test('长帧阈值测试', () {
      // 256字节总长度 (255字节负载 + 1字节命令)
      final payload = List.generate(255, (i) => i % 256);
      // Flag(0x40) + Len(0x00) + LenH(0x01) + Cmd(0xF8) + Payload(255字节)
      final data = [0x40, 0x00, 0x01, 0xF8];
      data.addAll(payload);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.totalPayloadLength, 256);
      expect(packet.flags?.isLongFrame, true);
      expect(packet.payload.length, 255);
    });
  });

  group('错误处理测试', () {
    test('数据过短返回null', () {
      final data = [0x00, 0x04]; // 只有2字节
      
      final packet = decoder.decode(data);
      expect(packet, isNull);
    });

    test('长度不匹配返回null', () {
      // 声明长度为10，但实际只有3字节负载
      final data = [0x00, 0x0A, 0xF8, 0x01, 0x02, 0x03];
      
      final packet = decoder.decode(data);
      expect(packet, isNull);
    });

    test('校验和错误返回null', () {
      // Flag(0x10) + Len(4) + Cmd(0xF8) + Payload(3字节) + 错误校验和
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03, 0xFF];
      
      final packet = decoder.decode(data);
      expect(packet, isNull);
    });

    test('无效命令返回null', () {
      // 使用无效命令值
      final data = [0x00, 0x04, 0xFF, 0x01, 0x02, 0x03];
      
      final packet = decoder.decode(data);
      expect(packet, isNull);
    });

    test('长帧长度字段不一致返回null', () {
      // 长帧标志但缺少LenH字段
      final data = [0x40, 0x04, 0xF8, 0x01, 0x02, 0x03];
      
      final packet = decoder.decode(data);
      expect(packet, isNull);
    });
  });

  group('校验和验证测试', () {
    test('正确校验和通过验证', () {
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03];
      
      // 计算正确的校验和
      int checksum = 0;
      for (int byte in data) {
        checksum ^= byte;
      }
      
      final isValid = decoder.verifyChecksum(data, checksum);
      expect(isValid, true);
    });

    test('错误校验和被检测', () {
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03];
      
      final isValid = decoder.verifyChecksum(data, 0x00);
      expect(isValid, false);
    });

    test('标志位解析', () {
      final flags = decoder.parseFlags(0x50);
      
      expect(flags.isLongFrame, true);
      expect(flags.checksumEnable, true);
    });
  });

  group('边界情况测试', () {
    test('最小数据包解码', () {
      // 只有命令，无负载
      final data = [0x00, 0x01, 0xF8];
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.len, 1);
      expect(packet.cmd, PacketCommand.normal);
      expect(packet.payload, isEmpty);
    });

    test('最大短帧解码', () {
      // 255字节总长度 (254字节负载 + 1字节命令)
      final payload = List.generate(254, (i) => i % 256);
      final data = [0x00, 0xFF, 0xF8];
      data.addAll(payload);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.len, 255);
      expect(packet.payload.length, 254);
      expect(packet.flags?.isLongFrame, false);
    });

    test('最小长帧解码', () {
      // 256字节总长度 (255字节负载 + 1字节命令)
      final payload = List.generate(255, (i) => i % 256);
      final data = [0x40, 0x00, 0x01, 0xF8]; // 256 = 0x0100
      data.addAll(payload);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.totalPayloadLength, 256);
      expect(packet.payload.length, 255);
      expect(packet.flags?.isLongFrame, true);
    });
  });

  group('数据包属性测试', () {
    test('标志位解析', () {
      final data = [0x50, 0x04, 0x00, 0xF8, 0x01, 0x02, 0x03];
      
      // 计算校验和
      int checksum = 0;
      for (int byte in data) {
        checksum ^= byte;
      }
      data.add(checksum);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      final flags = packet!.flags;
      expect(flags?.isLongFrame, true);
      expect(flags?.checksumEnable, true);
    });

    test('总负载长度计算', () {
      // 长帧测试
      final payload = List.generate(300, (i) => i % 256);
      final data = [0x40, 0x2D, 0x01, 0x20]; // 301 = 0x012D
      data.addAll(payload);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      expect(packet!.totalPayloadLength, 301);
    });

    test('数据包字符串表示', () {
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03];
      
      // 计算校验和
      int checksum = 0;
      for (int byte in data) {
        checksum ^= byte;
      }
      data.add(checksum);
      
      final packet = decoder.decode(data);
      
      expect(packet, isNotNull);
      final str = packet!.toString();
      expect(str, contains('InterChipPacket'));
      expect(str, contains('flag: 0x10'));
      expect(str, contains('len: 4'));
      expect(str, contains('cmd: 0xf8'));
    });
  });

  group('格式验证测试', () {
    test('有效数据包格式', () {
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03, 0x1A];
      
      final isValid = decoder.isValidPacketFormat(data);
      expect(isValid, true);
    });

    test('无效数据包格式', () {
      final data = [0x10, 0x04]; // 数据不完整
      
      final isValid = decoder.isValidPacketFormat(data);
      expect(isValid, false);
    });

    test('期望长度计算', () {
      final data = [0x10, 0x04, 0xF8]; // Flag + Len + Cmd
      
      final expectedLength = decoder.calculateExpectedLength(data);
      expect(expectedLength, isNotNull);
      expect(expectedLength! > 0, true);
    });
  });
}