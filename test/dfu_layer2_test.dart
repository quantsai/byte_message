import 'package:byte_message/src/models/layer2/dfu_cmd.dart';
import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';

/// 构造一个 DfuMessage 的测试辅助函数。
///
/// 参数：
/// - [dfuCmd] DFU 子命令（u8）。
/// - [dfuVersion] DFU 协议版本（u8）。
/// - [payload] DFU 二层负载字节数组。
/// 返回：
/// - [DfuMessage] 用于编码的消息对象。
DfuMessage buildDfuMsg(DfuCmd dfuCmd, int dfuVersion, List<int> payload) {
  return DfuMessage(
      dfuCmd: dfuCmd, dfuVersion: dfuVersion, dfuPayload: payload);
}

void main() {
  group('Layer2 DFU Encoder/Decoder', () {
    test('encode returns dfuCmd|dfuVersion|dfuPayload and decoder roundtrip',
        () {
      final msg = buildDfuMsg(DfuCmd.getDeviceInfo, 0x02, const [0xAA, 0xBB]);
      final encoder = DfuEncoder();
      final bytes = encoder.encode(msg);

      expect(bytes, equals(const [0x01, 0x02, 0xAA, 0xBB]));

      final decoder = DfuDecoder();
      final decoded = decoder.decode(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.dfuCmd, equals(DfuCmd.getDeviceInfo));
      expect(decoded.dfuVersion, equals(0x02));
      expect(decoded.dfuPayload, equals(const [0xAA, 0xBB]));
    });

    test('decoder returns null if bytes length < 2 (no cmd+version)', () {
      final decoder = DfuDecoder();
      expect(decoder.decode(const [0x01]), isNull);
      expect(decoder.decode(const []), isNull);
    });
  });
}
