import 'package:test/test.dart';
import 'package:byte_message/src/utils/packet_utils.dart';
import 'package:byte_message/src/constants/packet_constants.dart';

/// 数据包工具类测试
/// 
/// 测试PacketUtils中的所有辅助函数
void main() {
  group('字节序转换工具测试', () {
    test('bytesToInt16 - 正常转换', () {
      expect(PacketUtils.bytesToInt16(0x34, 0x12), 0x1234);
      expect(PacketUtils.bytesToInt16(0xFF, 0xFF), 0xFFFF);
      expect(PacketUtils.bytesToInt16(0x00, 0x00), 0x0000);
      expect(PacketUtils.bytesToInt16(0x01, 0x00), 0x0001);
      expect(PacketUtils.bytesToInt16(0x00, 0x01), 0x0100);
    });

    test('bytesToInt16 - 边界值测试', () {
      expect(PacketUtils.bytesToInt16(0x00, 0xFF), 0xFF00);
      expect(PacketUtils.bytesToInt16(0xFF, 0x00), 0x00FF);
      expect(PacketUtils.bytesToInt16(0x80, 0x7F), 0x7F80);
    });

    test('bytesToInt16 - 无效输入抛出异常', () {
      expect(() => PacketUtils.bytesToInt16(-1, 0), throwsArgumentError);
      expect(() => PacketUtils.bytesToInt16(256, 0), throwsArgumentError);
      expect(() => PacketUtils.bytesToInt16(0, -1), throwsArgumentError);
      expect(() => PacketUtils.bytesToInt16(0, 256), throwsArgumentError);
    });

    test('int16ToBytes - 正常转换', () {
      expect(PacketUtils.int16ToBytes(0x1234), [0x34, 0x12]);
      expect(PacketUtils.int16ToBytes(0xFFFF), [0xFF, 0xFF]);
      expect(PacketUtils.int16ToBytes(0x0000), [0x00, 0x00]);
      expect(PacketUtils.int16ToBytes(0x0001), [0x01, 0x00]);
      expect(PacketUtils.int16ToBytes(0x0100), [0x00, 0x01]);
    });

    test('int16ToBytes - 边界值测试', () {
      expect(PacketUtils.int16ToBytes(0xFF00), [0x00, 0xFF]);
      expect(PacketUtils.int16ToBytes(0x00FF), [0xFF, 0x00]);
      expect(PacketUtils.int16ToBytes(0x7F80), [0x80, 0x7F]);
    });

    test('int16ToBytes - 无效输入抛出异常', () {
      expect(() => PacketUtils.int16ToBytes(-1), throwsArgumentError);
      expect(() => PacketUtils.int16ToBytes(65536), throwsArgumentError);
      expect(() => PacketUtils.int16ToBytes(0x10000), throwsArgumentError);
    });

    test('字节序转换往返测试', () {
      final testValues = [0x0000, 0x0001, 0x0100, 0x1234, 0xABCD, 0xFFFF];
      
      for (final value in testValues) {
        final bytes = PacketUtils.int16ToBytes(value);
        final reconstructed = PacketUtils.bytesToInt16(bytes[0], bytes[1]);
        expect(reconstructed, value, reason: '值 0x${value.toRadixString(16)} 往返转换失败');
      }
    });
  });

  group('校验和计算工具测试', () {
    test('calculateXorChecksum - 基本计算', () {
      expect(PacketUtils.calculateXorChecksum([]), 0x00);
      expect(PacketUtils.calculateXorChecksum([0x00]), 0x00);
      expect(PacketUtils.calculateXorChecksum([0xFF]), 0xFF);
      expect(PacketUtils.calculateXorChecksum([0x01, 0x02]), 0x03);
      expect(PacketUtils.calculateXorChecksum([0xFF, 0xFF]), 0x00);
    });

    test('calculateXorChecksum - 复杂数据', () {
      expect(PacketUtils.calculateXorChecksum([0x10, 0x04, 0xF8, 0x01, 0x02, 0x03]), 0xEC);
      expect(PacketUtils.calculateXorChecksum([0xAA, 0x55, 0xAA, 0x55]), 0x00);
      expect(PacketUtils.calculateXorChecksum([0x12, 0x34, 0x56, 0x78]), 0x08);
    });

    test('calculateXorChecksum - 无效输入抛出异常', () {
      expect(() => PacketUtils.calculateXorChecksum([-1]), throwsArgumentError);
      expect(() => PacketUtils.calculateXorChecksum([256]), throwsArgumentError);
      expect(() => PacketUtils.calculateXorChecksum([0, 255, 256]), throwsArgumentError);
    });

    test('verifyXorChecksum - 正确校验', () {
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03];
      final checksum = PacketUtils.calculateXorChecksum(data);
      
      expect(PacketUtils.verifyXorChecksum(data, checksum), true);
      expect(PacketUtils.verifyXorChecksum(data, checksum ^ 0x01), false);
      expect(PacketUtils.verifyXorChecksum([], 0x00), true);
    });

    test('verifyXorChecksum - 无效校验和抛出异常', () {
      final data = [0x01, 0x02, 0x03];
      
      expect(() => PacketUtils.verifyXorChecksum(data, -1), throwsArgumentError);
      expect(() => PacketUtils.verifyXorChecksum(data, 256), throwsArgumentError);
    });
  });

  group('数据验证工具测试', () {
    test('isValidPayloadLength - 有效长度', () {
      expect(PacketUtils.isValidPayloadLength(0), true);
      expect(PacketUtils.isValidPayloadLength(1), true);
      expect(PacketUtils.isValidPayloadLength(255), true);
      expect(PacketUtils.isValidPayloadLength(65535), true);
      expect(PacketUtils.isValidPayloadLength(PacketConstants.MAX_PAYLOAD_SHORT), true);
      expect(PacketUtils.isValidPayloadLength(PacketConstants.MAX_PAYLOAD_LONG), true);
    });

    test('isValidPayloadLength - 无效长度', () {
      expect(PacketUtils.isValidPayloadLength(-1), false);
      expect(PacketUtils.isValidPayloadLength(65536), false);
      expect(PacketUtils.isValidPayloadLength(PacketConstants.MAX_PAYLOAD_LONG + 1), false);
    });

    test('isResponseCommand - 应答命令检测', () {
      expect(PacketUtils.isResponseCommand(PacketConstants.RESPONSE_OK), true);
      expect(PacketUtils.isResponseCommand(PacketConstants.RESPONSE_ERROR), true);
      expect(PacketUtils.isResponseCommand(PacketConstants.RESPONSE_INVALID), true);
      expect(PacketUtils.isResponseCommand(PacketConstants.RESPONSE_FORCE_SYNC), true);
      expect(PacketUtils.isResponseCommand(PacketConstants.RESPONSE_TEST_COMMUNICATION), true);
      
      // 非应答命令
      expect(PacketUtils.isResponseCommand(0xF8), false);
      expect(PacketUtils.isResponseCommand(0x20), false);
      expect(PacketUtils.isResponseCommand(0x00), true); // RESPONSE_FORCE_SYNC = 0x00
    });

    test('isCommandProtocol - 命令协议检测', () {
      expect(PacketUtils.isCommandProtocol(PacketConstants.CMD_CONTROL_BUS), true);
      expect(PacketUtils.isCommandProtocol(0xF8), true); // CMD_CONTROL_BUS = 0xF8
      expect(PacketUtils.isCommandProtocol(0x20), false);
    });

    test('isDfuProtocol - DFU协议检测', () {
      expect(PacketUtils.isDfuProtocol(PacketConstants.CMD_DFU), true);
      expect(PacketUtils.isDfuProtocol(0xF8), false);
      expect(PacketUtils.isDfuProtocol(PacketConstants.CMD_CONTROL_BUS), false);
    });

    test('isValidLength - 长度一致性验证', () {
      // 短帧测试
      expect(PacketUtils.isValidLength(5, null, 5), true);
      expect(PacketUtils.isValidLength(5, null, 4), false);
      expect(PacketUtils.isValidLength(5, null, 6), false);
      
      // 长帧测试
      expect(PacketUtils.isValidLength(0x00, 0x01, 256), true);
      expect(PacketUtils.isValidLength(0x2D, 0x01, 301), true);
      expect(PacketUtils.isValidLength(0x00, 0x01, 255), false);
      
      // 无效输入
      expect(PacketUtils.isValidLength(-1, null, 5), false);
      expect(PacketUtils.isValidLength(256, null, 5), false);
      expect(PacketUtils.isValidLength(5, -1, 5), false);
      expect(PacketUtils.isValidLength(5, 256, 5), false);
    });

    test('isValidCommand - 命令有效性验证', () {
      expect(PacketUtils.isValidCommand(0x00), true);
      expect(PacketUtils.isValidCommand(0xF8), true);
      expect(PacketUtils.isValidCommand(0x20), true);
      expect(PacketUtils.isValidCommand(0xFF), true);
      
      expect(PacketUtils.isValidCommand(-1), false);
      expect(PacketUtils.isValidCommand(256), false);
    });

    test('isValidPayload - 负载有效性验证', () {
      expect(PacketUtils.isValidPayload([]), true);
      expect(PacketUtils.isValidPayload([0x00]), true);
      expect(PacketUtils.isValidPayload([0xFF]), true);
      expect(PacketUtils.isValidPayload([0x01, 0x02, 0x03]), true);
      expect(PacketUtils.isValidPayload(List.generate(1000, (i) => i % 256)), true);
      
      expect(PacketUtils.isValidPayload([-1]), false);
      expect(PacketUtils.isValidPayload([256]), false);
      expect(PacketUtils.isValidPayload([0, 255, 256]), false);
    });
  });

  group('数据包分析工具测试', () {
    test('analyzePacket - 空数据包', () {
      final analysis = PacketUtils.analyzePacket([]);
      expect(analysis['error'], 'Empty packet data');
    });

    test('analyzePacket - 短帧分析', () {
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03];
      final analysis = PacketUtils.analyzePacket(data);
      
      expect(analysis['flag'], '0x10');
      expect(analysis['longFrame'], false);
      expect(analysis['checksumEnabled'], true);
      expect(analysis['len'], 4);
      expect(analysis['totalLength'], 4);
      expect(analysis['actualPacketLength'], 6);
    });

    test('analyzePacket - 长帧分析', () {
      final data = [0x50, 0x2D, 0x01, 0x20];
      data.addAll(List.generate(300, (i) => i % 256));
      
      final analysis = PacketUtils.analyzePacket(data);
      
      expect(analysis['flag'], '0x50');
      expect(analysis['longFrame'], true);
      expect(analysis['checksumEnabled'], true);
      expect(analysis['len'], 0x2D);
      expect(analysis['lenH'], 0x01);
      expect(analysis['totalLength'], 301);
    });

    test('analyzePacket - 不完整数据包', () {
      final analysis1 = PacketUtils.analyzePacket([0x10]);
      expect(analysis1['error'], contains('missing Len field'));
      
      final analysis2 = PacketUtils.analyzePacket([0x50, 0x04]);
      expect(analysis2['error'], contains('missing LenH field'));
    });
  });

  group('格式化工具测试', () {
    test('formatBytes - 默认分隔符', () {
      expect(PacketUtils.formatBytes([]), '');
      expect(PacketUtils.formatBytes([0x00]), '0x00');
      expect(PacketUtils.formatBytes([0x01, 0x02]), '0x01 0x02');
      expect(PacketUtils.formatBytes([0xFF, 0xAB, 0xCD]), '0xff 0xab 0xcd');
    });

    test('formatBytes - 自定义分隔符', () {
      expect(PacketUtils.formatBytes([0x01, 0x02, 0x03], '-'), '0x01-0x02-0x03');
      expect(PacketUtils.formatBytes([0x01, 0x02, 0x03], ''), '0x010x020x03');
      expect(PacketUtils.formatBytes([0x01, 0x02, 0x03], ', '), '0x01, 0x02, 0x03');
    });

    test('parseHexString - 各种格式', () {
      expect(PacketUtils.parseHexString('01 02 03'), [0x01, 0x02, 0x03]);
      expect(PacketUtils.parseHexString('0x01 0x02 0x03'), [0x01, 0x02, 0x03]);
      expect(PacketUtils.parseHexString('01-02-03'), [0x01, 0x02, 0x03]);
      expect(PacketUtils.parseHexString('010203'), [0x01, 0x02, 0x03]);
      expect(PacketUtils.parseHexString('FF AA 55'), [0xFF, 0xAA, 0x55]);
      expect(PacketUtils.parseHexString('ff aa 55'), [0xFF, 0xAA, 0x55]);
    });

    test('parseHexString - 复杂格式', () {
      expect(PacketUtils.parseHexString('0x10, 0x04, 0xF8'), [0x10, 0x04, 0xF8]);
      expect(PacketUtils.parseHexString('10:04:F8'), [0x10, 0x04, 0xF8]);
      expect(PacketUtils.parseHexString('10\t04\nF8'), [0x10, 0x04, 0xF8]);
    });

    test('parseHexString - 无效格式抛出异常', () {
      expect(() => PacketUtils.parseHexString('1'), throwsArgumentError);
      expect(() => PacketUtils.parseHexString('123'), throwsArgumentError);
      expect(() => PacketUtils.parseHexString('GG'), throwsArgumentError);
      expect(() => PacketUtils.parseHexString('0x1'), throwsArgumentError);
    });

    test('格式化往返测试', () {
      final testData = [
        <int>[],
        [0x00],
        [0xFF],
        [0x01, 0x02, 0x03],
        [0xAA, 0x55, 0xFF, 0x00],
        List.generate(10, (i) => i * 16),
      ];

      for (final data in testData) {
        final formatted = PacketUtils.formatBytes(data);
        if (data.isNotEmpty) {
          // 移除0x前缀进行解析测试
          final cleanFormatted = formatted.replaceAll('0x', '');
          final parsed = PacketUtils.parseHexString(cleanFormatted);
          expect(parsed, data, reason: '数据 $data 格式化往返失败');
        }
      }
    });
  });

  group('调试工具测试', () {
    test('generateDebugInfo - 完整信息', () {
      final data = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03];
      final debugInfo = PacketUtils.generateDebugInfo(data);
      
      expect(debugInfo, contains('Packet Debug Info'));
      expect(debugInfo, contains('Raw data:'));
      expect(debugInfo, contains('Length: 6 bytes'));
      expect(debugInfo, contains('flag: 0x10'));
      expect(debugInfo, contains('len: 4'));
    });

    test('generateDebugInfo - 空数据包', () {
      final debugInfo = PacketUtils.generateDebugInfo([]);
      
      expect(debugInfo, contains('Packet Debug Info'));
      expect(debugInfo, contains('Length: 0 bytes'));
      expect(debugInfo, contains('error: Empty packet data'));
    });

    test('generateDebugInfo - 长帧数据包', () {
      final data = [0x50, 0x2D, 0x01, 0x20];
      data.addAll(List.generate(10, (i) => i)); // 简化的负载
      
      final debugInfo = PacketUtils.generateDebugInfo(data);
      
      expect(debugInfo, contains('longFrame: true'));
      expect(debugInfo, contains('checksumEnabled: true'));
      expect(debugInfo, contains('lenH: 1'));
    });
  });
}