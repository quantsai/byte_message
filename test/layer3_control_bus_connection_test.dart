import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';

void main() {
  // 测试辅助：按生产实现的规则（每段 u32 十进制左补零到固定宽度，默认 10 位）
  // 将三段序列号拼接为字符串，以提升断言的可读性与一致性。
  String composeSerialStringFromSegments(List<int> segments, {int width = 10}) {
    return segments.map((v) => v.toString().padLeft(width, '0')).join();
  }

  group('Layer3 设备连接 - 请求连接协议', () {
    test('请求编码 - 协议版本 0x02（默认）', () {
      final payload = DeviceConnectionReq().encode();
      expect(payload, [0x02]);
    });

    test('请求编码 - 非法版本抛出 RangeError', () {
      expect(() => DeviceConnectionReq(protocolVersion: 256),
          throwsA(isA<RangeError>()));
      expect(() => DeviceConnectionReq(protocolVersion: -1),
          throwsA(isA<RangeError>()));
    });

    test('应答解码 - 全零示例（长度28）', () {
      // 12 (model) + 2 (fw) + 2 (hw) + 4*3 (sn) = 28 字节
      final bytes = List<int>.filled(28, 0x00);
      final resp = DeviceConnectionRes.fromBytes(bytes);
      expect(resp.model, '');
      expect(resp.firmwareVersion, '0.0.0');
      expect(resp.hardwareVersion, '0.0.0');
      // 序列号断言：三段零按 10 位左补零拼接，总长度 30 位
      expect(resp.serialNumber, composeSerialStringFromSegments([0, 0, 0]));
    });

    test('应答解码 - 长度不匹配抛出 ArgumentError', () {
      final bad = List<int>.filled(27, 0x00);
      expect(() => DeviceConnectionRes.fromBytes(bad),
          throwsA(isA<ArgumentError>()));
    });
  });
}
