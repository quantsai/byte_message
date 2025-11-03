import 'package:test/test.dart';
import 'package:byte_message/src/encoders/inter_chip_encoder.dart';
import 'package:byte_message/src/decoders/inter_chip_decoder.dart';
import 'package:byte_message/src/models/packet_models.dart';
import 'package:byte_message/src/models/packet_command.dart';

/// 集成测试
///
/// 测试编码器和解码器的完整流程，确保编码后的数据能正确解码
void main() {
  late InterChipEncoder encoder;
  late InterChipDecoder decoder;

  setUp(() {
    encoder = InterChipEncoder();
    decoder = InterChipDecoder();
  });

  group('编码解码往返测试', () {
    test('短帧往返测试 - 无校验和', () {
      // 创建原始数据包
      final originalPacket = InterChipPacket(
        flag: 0x00,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.flag, originalPacket.flag);
      expect(decodedPacket.len, originalPacket.len);
      expect(decodedPacket.cmd, originalPacket.cmd);
      expect(decodedPacket.payload, originalPacket.payload);
      expect(decodedPacket.checksum, originalPacket.checksum);
    });

    test('短帧往返测试 - 有校验和', () {
      // 创建带校验和的数据包
      final originalPacket = InterChipPacket(
        flag: 0x10,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.flag, originalPacket.flag);
      expect(decodedPacket.len, originalPacket.len);
      expect(decodedPacket.cmd, originalPacket.cmd);
      expect(decodedPacket.payload, originalPacket.payload);
      expect(decodedPacket.checksum, isNotNull);
    });

    test('长帧往返测试 - 无校验和', () {
      // 创建长帧数据包
      final payload = List.generate(300, (i) => i % 256);
      final originalPacket = InterChipPacket(
        flag: 0x40, // 长帧标志
        cmd: PacketCommand.dfu,
        payload: payload,
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.flag! & 0x40, 0x40); // 验证长帧标志
      expect(decodedPacket.cmd, originalPacket.cmd);
      expect(decodedPacket.payload, originalPacket.payload);
      expect(decodedPacket.checksum, null); // 无校验和标志时应为null
    });

    test('长帧往返测试 - 有校验和', () {
      // 创建长帧数据包
      final payload = List.generate(300, (i) => i % 256);
      final originalPacket = InterChipPacket(
        flag: 0x50, // 长帧标志 + 校验和标志
        cmd: PacketCommand.dfu,
        payload: payload,
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.flag! & 0x40, 0x40); // 验证长帧标志
      expect(decodedPacket.flag! & 0x10, 0x10); // 验证校验和标志
      expect(decodedPacket.cmd, originalPacket.cmd);
      expect(decodedPacket.payload, originalPacket.payload);
      expect(decodedPacket.checksum, isNotNull); // 有校验和标志时应不为null
    });

    test('空负载往返测试', () {
      // 创建空负载数据包
      final originalPacket = InterChipPacket(
        flag: 0x00,
        len: 1,
        cmd: PacketCommand.normal,
        payload: [],
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.flag, originalPacket.flag);
      expect(decodedPacket.len, originalPacket.len);
      expect(decodedPacket.cmd, originalPacket.cmd);
      expect(decodedPacket.payload, isEmpty);
    });
  });

  group('不同命令类型测试', () {
    test('所有命令类型往返测试', () {
      final commands = [PacketCommand.normal, PacketCommand.dfu];

      for (final cmd in commands) {
        final originalPacket = InterChipPacket(
          flag: 0x10,
          len: 4,
          cmd: cmd,
          payload: [0x01, 0x02, 0x03],
        );

        // 编码
        final encodedData = encoder.encode(originalPacket);
        expect(encodedData, isNotNull, reason: '命令 $cmd 编码失败');

        // 解码
        final decodedPacket = decoder.decode(encodedData);
        expect(decodedPacket, isNotNull, reason: '命令 $cmd 解码失败');

        // 验证命令一致性
        expect(decodedPacket!.cmd, cmd, reason: '命令 $cmd 不匹配');
      }
    });
  });

  group('边界条件往返测试', () {
    test('最大短帧往返测试', () {
      // 254字节负载 + 1字节命令 = 255字节总长度
      final payload = List.generate(254, (i) => i % 256);
      final originalPacket = InterChipPacket(
        flag: 0x00,
        len: 255,
        cmd: PacketCommand.normal,
        payload: payload,
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.len, 255);
      expect(decodedPacket.payload.length, 254);
      expect(decodedPacket.flags?.isLongFrame, false);
    });

    test('最小长帧往返测试', () {
      // 256字节负载（最小长帧）
      final payload = List.generate(255, (i) => i % 256);
      final originalPacket = InterChipPacket(
        flag: 0x40, // 长帧标志
        cmd: PacketCommand.normal,
        payload: payload,
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.totalPayloadLength, 256);
      expect(decodedPacket.payload.length, 255);
      expect(decodedPacket.flags?.isLongFrame, true);
    });

    test('最大长帧往返测试', () {
      // 65534字节负载 + 1字节命令 = 65535字节总长度
      final payload = List.generate(65534, (i) => i % 256);
      final originalPacket = InterChipPacket(
        flag: 0x40,
        len: 0xFF,
        lenH: 0xFF,
        cmd: PacketCommand.normal,
        payload: payload,
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 解码
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNotNull);

      // 验证数据一致性
      expect(decodedPacket!.totalPayloadLength, 65535);
      expect(decodedPacket.payload.length, 65534);
      expect(decodedPacket.flags?.isLongFrame, true);
    });
  });

  group('校验和完整性测试', () {
    test('校验和计算一致性', () {
      final testCases = [
        [0x01, 0x02, 0x03],
        [0xFF, 0x00, 0xAA, 0x55],
        List.generate(100, (i) => i % 256),
        List.generate(200, (i) => (i * 3) % 256), // 减少到200以避免超出u8范围
      ];

      for (final payload in testCases) {
        final originalPacket = InterChipPacket(
          flag: 0x10, // 启用校验和
          cmd: PacketCommand.normal,
          payload: payload,
        );

        // 编码
        final encodedData = encoder.encode(originalPacket);
        expect(encodedData, isNotNull);

        // 解码
        final decodedPacket = decoder.decode(encodedData);
        expect(decodedPacket, isNotNull);

        // 验证校验和存在且正确
        expect(decodedPacket!.checksum, isNotNull);
        expect(decodedPacket.payload, payload);
      }
    });

    test('校验和错误检测', () {
      final originalPacket = InterChipPacket(
        flag: 0x10,
        len: 4,
        cmd: PacketCommand.normal,
        payload: [0x01, 0x02, 0x03],
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 故意修改校验和
      encodedData[encodedData.length - 1] = 0xFF;

      // 解码应该失败
      final decodedPacket = decoder.decode(encodedData);
      expect(decodedPacket, isNull);
    });
  });

  group('性能测试', () {
    test('大量数据包往返测试', () {
      const packetCount = 100;
      final packets = <InterChipPacket>[];

      // 生成测试数据包
      for (int i = 0; i < packetCount; i++) {
        final payload = List.generate(i % 100 + 1, (j) => (i + j) % 256);
        packets.add(
          InterChipPacket(
            flag: i % 2 == 0 ? 0x00 : 0x10,
            len: payload.length + 1,
            cmd: PacketCommand.values[i % PacketCommand.values.length],
            payload: payload,
          ),
        );
      }

      // 批量编码解码
      for (int i = 0; i < packets.length; i++) {
        final originalPacket = packets[i];

        // 编码
        final encodedData = encoder.encode(originalPacket);
        expect(encodedData, isNotNull, reason: '数据包 $i 编码失败');

        // 解码
        final decodedPacket = decoder.decode(encodedData);
        expect(decodedPacket, isNotNull, reason: '数据包 $i 解码失败');

        // 验证数据一致性
        expect(decodedPacket!.cmd, originalPacket.cmd, reason: '数据包 $i 命令不匹配');
        expect(
          decodedPacket.payload,
          originalPacket.payload,
          reason: '数据包 $i 负载不匹配',
        );
      }
    });

    test('长帧性能测试', () {
      // 测试不同大小的长帧
      final sizes = [256, 1024, 4096, 16384, 32768];

      for (final size in sizes) {
        final payload = List.generate(size - 1, (i) => i % 256);
        final originalPacket = InterChipPacket(
          flag: 0x40, // 长帧标志
          cmd: PacketCommand.dfu,
          payload: payload,
        );

        // 编码
        final stopwatch = Stopwatch()..start();
        final encodedData = encoder.encode(originalPacket);
        final encodeTime = stopwatch.elapsedMicroseconds;
        stopwatch.reset();

        expect(encodedData, isNotNull);

        // 解码
        final decodedPacket = decoder.decode(encodedData);
        final decodeTime = stopwatch.elapsedMicroseconds;
        stopwatch.stop();

        expect(decodedPacket, isNotNull);
        expect(decodedPacket!.payload.length, size - 1);

        // 性能日志（可选）
        print('大小: $size 字节, 编码: $encodeTime μs, 解码: $decodeTime μs');
      }
    });
  });

  group('错误恢复测试', () {
    test('部分损坏数据恢复', () {
      final originalPacket = InterChipPacket(
        flag: 0x10,
        len: 10,
        cmd: PacketCommand.normal,
        payload: List.generate(9, (i) => i),
      );

      // 编码
      final encodedData = encoder.encode(originalPacket);
      expect(encodedData, isNotNull);

      // 测试各种损坏情况
      final corruptedCases = [
        // 修改标志位
        () {
          final corrupted = List<int>.from(encodedData);
          corrupted[0] = 0xFF;
          return corrupted;
        },
        // 修改长度
        () {
          final corrupted = List<int>.from(encodedData);
          corrupted[1] = 0xFF;
          return corrupted;
        },
        // 修改命令
        () {
          final corrupted = List<int>.from(encodedData);
          corrupted[2] = 0xFF;
          return corrupted;
        },
        // 截断数据
        () {
          return encodedData.sublist(0, encodedData.length - 2);
        },
      ];

      for (int i = 0; i < corruptedCases.length; i++) {
        final corruptedData = corruptedCases[i]();
        final decodedPacket = decoder.decode(corruptedData);
        expect(decodedPacket, isNull, reason: '损坏情况 $i 应该返回 null');
      }
    });
  });
}
