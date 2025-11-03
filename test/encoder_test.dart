import 'package:test/test.dart';
import 'package:byte_message/src/encoders/inter_chip_encoder.dart';
import 'package:byte_message/src/models/packet_models.dart';
import 'package:byte_message/src/models/packet_command.dart';
import 'package:byte_message/src/interfaces/packet_encoder.dart';

/// 编码器测试
/// 
/// 测试InterChipEncoder的编码功能
void main() {
  late InterChipEncoder encoder;

  setUp(() {
    encoder = InterChipEncoder();
  });

  group('短帧编码测试', () {
    test('基础短帧编码 - 默认启用校验和', () {
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final encoded = encoder.encode(packet);
      
      // 验证标志位 (有校验和，短帧) - 编码器默认启用校验和
      expect(encoded[0], 0x10);
      
      // 验证长度 (3字节负载 + 1字节命令 = 4)
      expect(encoded[1], 4);
      
      // 验证命令
      expect(encoded[2], PacketCommand.normal.value);
      
      // 验证负载
      expect(encoded[3], 0x01);
      expect(encoded[4], 0x02);
      expect(encoded[5], 0x03);
      
      // 验证校验和存在
      expect(encoded.length, 7); // Flag + Len + Cmd + Payload(3) + Checksum
    });

    test('指定标志位的短帧编码', () {
      final packet = InterChipPacket(
        flag: 0x00, // 无校验和，短帧
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final encoded = encoder.encode(packet);
      
      // 验证标志位
      expect(encoded[0], 0x00);
      
      // 验证长度
      expect(encoded[1], 4);
      
      // 验证命令
      expect(encoded[2], PacketCommand.normal.value);
      
      // 验证负载
      expect(encoded[3], 0x01);
      expect(encoded[4], 0x02);
      expect(encoded[5], 0x03);
      
      // 无校验和
      expect(encoded.length, 6); // Flag + Len + Cmd + Payload(3)
    });

    test('空负载短帧编码', () {
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [],
      );

      final encoded = encoder.encode(packet);
      
      // 验证长度 (0字节负载 + 1字节命令 = 1)
      expect(encoded[1], 1);
      
      // 验证命令
      expect(encoded[2], PacketCommand.normal.value);
      
      // 验证有校验和
      expect(encoded.length, 4); // Flag + Len + Cmd + Checksum
    });
  });

  group('长帧编码测试', () {
    test('基础长帧编码', () {
      final payload = List.generate(300, (i) => i % 256);
      final packet = InterChipPacket(
        cmd: PacketCommand.dfu,
        payload: payload,
      );

      final encoded = encoder.encode(packet);
      
      // 验证标志位 (有校验和，长帧)
      expect(encoded[0], 0x50);
      
      // 验证长度 (小端序: 301 = 0x012D)
      expect(encoded[1], 0x2D); // len (低字节)
      expect(encoded[2], 0x01); // lenH (高字节)
      
      // 验证命令
      expect(encoded[3], PacketCommand.dfu.value);
      
      // 验证负载开始
      expect(encoded[4], 0x00);
      expect(encoded[5], 0x01);
      expect(encoded[6], 0x02);
      
      // 验证负载结束
      expect(encoded[303], 0x2B); // 299 % 256 = 43 = 0x2B
      
      // 验证有校验和
      expect(encoded.length, 305); // Flag + Len + LenH + Cmd + Payload(300) + Checksum
    });

    test('指定标志位的长帧编码', () {
      final payload = List.generate(300, (i) => i % 256);
      final packet = InterChipPacket(
        flag: 0x40, // 无校验和，长帧
        cmd: PacketCommand.dfu,
        payload: payload,
      );

      final encoded = encoder.encode(packet);
      
      // 验证标志位
      expect(encoded[0], 0x40);
      
      // 验证长度
      expect(encoded[1], 0x2D); // len (低字节)
      expect(encoded[2], 0x01); // lenH (高字节)
      
      // 无校验和
      expect(encoded.length, 304); // Flag + Len + LenH + Cmd + Payload(300)
    });

    test('长帧阈值测试', () {
      // 253字节负载 (短帧最大值: 253 + 1(cmd) = 254 <= maxStandardFramePayload)
      final shortPayload = List.generate(253, (i) => i % 256);
      final shortPacket = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: shortPayload,
      );

      final shortEncoded = encoder.encode(shortPacket);
      expect(shortEncoded[0] & 0x40, 0); // 不是长帧

      // 254字节负载 (长帧最小值: 254 + 1(cmd) = 255 > maxStandardFramePayload)
      final longPayload = List.generate(254, (i) => i % 256);
      final longPacket = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: longPayload,
      );

      final longEncoded = encoder.encode(longPacket);
      expect(longEncoded[0] & 0x40, 0x40); // 是长帧
    });
  });

  group('错误处理测试', () {
    test('负载过大抛出异常', () {
      final largePayload = List.generate(65536, (i) => i % 256);
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: largePayload,
      );

      expect(() => encoder.encode(packet), 
             throwsA(isA<EncoderException>()));
    });

    test('长度不匹配抛出异常', () {
      final packet = InterChipPacket(
        len: 10, // 错误的长度
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03], // 实际长度是4 (3+1)
      );

      expect(() => encoder.encode(packet), 
             throwsA(isA<EncoderException>()));
    });
  });

  group('校验和计算测试', () {
    test('校验和计算正确性', () {
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final encoded = encoder.encode(packet);
      
      // 手动计算校验和 (对除校验和外的所有字节进行XOR)
      int expectedChecksum = 0;
      for (int i = 0; i < encoded.length - 1; i++) {
        expectedChecksum ^= encoded[i];
      }
      
      // 验证校验和
      expect(encoded[encoded.length - 1], expectedChecksum);
    });

    test('不同负载的校验和不同', () {
      final packet1 = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final packet2 = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x04, 0x05, 0x06],
      );

      final encoded1 = encoder.encode(packet1);
      final encoded2 = encoder.encode(packet2);
      
      // 校验和应该不同
      expect(encoded1[encoded1.length - 1], 
             isNot(equals(encoded2[encoded2.length - 1])));
    });
  });

  group('标志位生成测试', () {
    test('自动生成标志位 - 短帧', () {
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final flags = encoder.generateFlags(packet);
      expect(flags.isLongFrame, false);
      expect(flags.checksumEnable, true); // 默认启用
    });

    test('自动生成标志位 - 长帧', () {
      final payload = List.generate(300, (i) => i % 256);
      final packet = InterChipPacket(
        cmd: PacketCommand.dfu,
        payload: payload,
      );

      final flags = encoder.generateFlags(packet);
      expect(flags.isLongFrame, true);
      expect(flags.checksumEnable, true); // 默认启用
    });
  });

  group('十六进制编码测试', () {
    test('十六进制字符串输出', () {
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final hexString = encoder.encodeToHex(packet);
      expect(hexString, isA<String>());
      expect(hexString.contains(' '), true); // 默认分隔符
      expect(hexString.toUpperCase(), equals(hexString)); // 大写
    });

    test('自定义分隔符的十六进制输出', () {
      final packet = InterChipPacket(
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      final hexString = encoder.encodeToHex(packet, separator: '-');
      expect(hexString.contains('-'), true);
    });
  });
}