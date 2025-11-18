import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';
import 'package:byte_message/src/models/layer2/control_bus_cmd.dart';

/// 构造一个 ControlBusMessage 的测试辅助函数。
///
/// 参数：
/// - [cbCmd] 二层子命令（枚举）。
/// - [payload] 二层负载字节数组。
/// 返回：
/// - [ControlBusMessage] 用于编码的消息对象。
ControlBusMessage buildCbMsg(CbCmd cbCmd, List<int> payload) {
  return ControlBusMessage(cbCmd: cbCmd, cbPayload: payload);
}

void main() {
  group('Layer2 ControlBus Encoder/Decoder', () {
    test('encode returns cbCmd|cbPayload and decoder roundtrip', () {
      final msg =
          buildCbMsg(CbCmd.batteryStatusRequest, const [0x01, 0x02, 0x03]);
      final encoder = ControlBusEncoder();
      final bytes = encoder.encode(msg);

      expect(bytes, equals(const [0x30, 0x01, 0x02, 0x03]));

      final decoder = ControlBusDecoder();
      final decoded = decoder.decode(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.cbCmd, equals(CbCmd.batteryStatusRequest));
      expect(decoded.cbPayload, equals(const [0x01, 0x02, 0x03]));
    });

    test('decoder returns null for empty payload', () {
      final decoder = ControlBusDecoder();
      final decoded = decoder.decode(const <int>[]);
      expect(decoded, isNull);
    });
  });
}
