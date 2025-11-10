import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';

void main() {
  group('Layer2 DFU Models: DfuMessage', () {
    test('fromBytes returns null when length < 2', () {
      expect(DfuMessage.fromBytes(const []), isNull);
      expect(DfuMessage.fromBytes(const [0x01]), isNull);
    });

    test('fromBytes parses cmd/version/payload', () {
      final msg = DfuMessage.fromBytes(const [0x01, 0x10, 0xAA, 0xBB]);
      expect(msg, isNotNull);
      expect(msg!.dfuCmd, equals(0x01));
      expect(msg.dfuVersion, equals(0x10));
      expect(msg.dfuPayload, equals(const [0xAA, 0xBB]));
    });

    test('toPacket builds InterChipPacket with CMD_DFU', () {
      final msg =
          DfuMessage(dfuCmd: 0x02, dfuVersion: 0x01, dfuPayload: const [0xAA]);
      final pkt = msg.toPacket();
      expect(pkt.cmd, equals(InterChipCmds.dfu));
      expect(pkt.payload, equals(const [0x02, 0x01, 0xAA]));
    });

    test('fromPacket returns null when cmd != CMD_DFU', () {
      final pkt = InterChipPacket(
          cmd: InterChipCmds.normal, payload: const [0x01, 0x10]);
      expect(DfuMessage.fromPacket(pkt), isNull);
    });

    test('fromPacket returns null when payload.length < 2', () {
      final pkt =
          InterChipPacket(cmd: InterChipCmds.dfu, payload: const [0x01]);
      expect(DfuMessage.fromPacket(pkt), isNull);
    });

    test('fromPacket parses dfu fields correctly', () {
      final pkt = InterChipPacket(
          cmd: InterChipCmds.dfu, payload: const [0x05, 0x02, 0x99]);
      final msg = DfuMessage.fromPacket(pkt);
      expect(msg, isNotNull);
      expect(msg!.dfuCmd, equals(0x05));
      expect(msg.dfuVersion, equals(0x02));
      expect(msg.dfuPayload, equals(const [0x99]));
    });
  });
}
