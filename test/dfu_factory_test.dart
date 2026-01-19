import 'package:test/test.dart';
import 'package:byte_message/src/factories/dfu_factory.dart';
import 'package:byte_message/src/protocols/layer1/inter_chip_encoder.dart';
import 'package:byte_message/src/models/layer1/inter_chip_models.dart';
import 'package:byte_message/src/models/layer2/dfu_cmd.dart';
import 'package:byte_message/src/protocols/layer2/dfu/dfu_decoder.dart';
import 'package:byte_message/src/protocols/layer3/dfu/dfu_blob.dart';
import 'package:byte_message/src/protocols/layer3/dfu/write_upgrade_bulk.dart';

void main() {
  group('DfuFactory', () {
    final factory = DfuFactory();

    group('GetDeviceInfo', () {
      test('encodeGetDeviceInfoReq produces correct bytes', () {
        final bytes = factory.encodeGetDeviceInfoReq();
        expect(bytes, isNotEmpty);
        // Add more specific assertions if needed, e.g. checking L2 command
      });

      test('decodeGetDeviceInfoRes parses valid response', () {
        final l3 = List<int>.filled(33, 0x00);
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        final result = factory.decodeGetDeviceInfoRes(raw);
        expect(result.status, InterChipCmds.ackOk);
        expect(result.data, isNotNull);
      });

      test('decodeGetDeviceInfoRes throws on invalid length', () {
        final l3 = List<int>.filled(32, 0x00); // Too short
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        expect(
          () => factory.decodeGetDeviceInfoRes(raw),
          throwsArgumentError,
        );
      });

      test('decodeGetDeviceInfoRes returns status only for non-AckOK', () {
        final ack = InterChipPacket(cmd: InterChipCmds.ackError, payload: []);
        final raw = InterChipEncoder().encode(ack);

        final result = factory.decodeGetDeviceInfoRes(raw);
        expect(result.status, InterChipCmds.ackError);
        expect(result.data, isNull);
      });
    });

    group('StartUpgrade', () {
      test('encodeStartUpgradeReq produces correct bytes', () {
        final bytes = factory.encodeStartUpgradeReq();
        expect(bytes, isNotEmpty);
      });

      test('decodeStartUpgradeRes parses valid response', () {
        final l3 = [0x01, 0x00]; // status=1, err=0
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        final result = factory.decodeStartUpgradeRes(raw);
        expect(result.status, InterChipCmds.ackOk);
        expect(result.data, isNotNull);
      });

      test('decodeStartUpgradeRes throws on invalid length', () {
        final l3 = [0x01]; // Too short
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        expect(
          () => factory.decodeStartUpgradeRes(raw),
          throwsArgumentError,
        );
      });
    });

    group('FinishUpgrade', () {
      test('encodeFinishUpgradeReq produces correct bytes', () {
        final bytes = factory.encodeFinishUpgradeReq();
        expect(bytes, isNotEmpty);
      });

      test('decodeFinishUpgradeRes parses valid response', () {
        final l3 = [0x01, 0x00];
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        final result = factory.decodeFinishUpgradeRes(raw);
        expect(result.status, InterChipCmds.ackOk);
        expect(result.data, isNotNull);
      });

      test('decodeFinishUpgradeRes throws on invalid length', () {
        final l3 = [0x01];
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        expect(
          () => factory.decodeFinishUpgradeRes(raw),
          throwsArgumentError,
        );
      });
    });

    group('WriteUpgradeChunk', () {
      test('encodeWriteUpgradeChunkReq produces correct bytes', () {
        final blob = DfuBlob(
          pageId: 1,
          blobId: 1,
          blobStart: 0,
          blobData: [1, 2, 3, 4],
        );
        final bytes = factory.encodeWriteUpgradeChunkReq(blob: blob);
        expect(bytes, isNotEmpty);
      });

      test('decodeWriteUpgradeChunkRes parses valid response', () {
        final l3 = [0x01, 0x00];
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        final result = factory.decodeWriteUpgradeChunkRes(raw);
        expect(result.status, InterChipCmds.ackOk);
        expect(result.data, isNotNull);
      });

      test('decodeWriteUpgradeChunkRes throws on invalid length', () {
        final l3 = [0x01];
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        expect(
          () => factory.decodeWriteUpgradeChunkRes(raw),
          throwsArgumentError,
        );
      });
    });

    group('WriteUpgradeBulk', () {
      test('encodeWriteUpgradeBulkReq produces correct bytes', () {
        final blob = DfuBlob(
          pageId: 1,
          blobId: 1,
          blobStart: 0,
          blobData: [1, 2, 3, 4],
        );
        final blobList = DfuBlobList(blobs: [blob]);
        final bytes = factory.encodeWriteUpgradeBulkReq(blobList: blobList);
        expect(bytes, isNotEmpty);
      });

      test('decodeWriteUpgradeBulkRes parses valid response', () {
        final l3 = [0x01, 0x00];
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        final result = factory.decodeWriteUpgradeBulkRes(raw);
        expect(result.status, InterChipCmds.ackOk);
        expect(result.data, isNotNull);
      });

      test('decodeWriteUpgradeBulkRes throws on invalid length', () {
        final l3 = [0x01];
        final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
        final raw = InterChipEncoder().encode(ack);

        expect(
          () => factory.decodeWriteUpgradeBulkRes(raw),
          throwsArgumentError,
        );
      });
    });

    group('Error Handling', () {
      test('decode throws ArgumentError on invalid L1 packet', () {
        final invalidRaw = [0x00]; // Too short for L1
        expect(
          () => factory.decodeGetDeviceInfoRes(invalidRaw),
          throwsArgumentError,
        );
        expect(
          () => factory.decodeStartUpgradeRes(invalidRaw),
          throwsArgumentError,
        );
        expect(
          () => factory.decodeFinishUpgradeRes(invalidRaw),
          throwsArgumentError,
        );
        expect(
          () => factory.decodeWriteUpgradeChunkRes(invalidRaw),
          throwsArgumentError,
        );
        expect(
          () => factory.decodeWriteUpgradeBulkRes(invalidRaw),
          throwsArgumentError,
        );
      });
    });
  });
}
