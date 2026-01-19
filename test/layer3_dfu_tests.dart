import 'package:test/test.dart';
import 'package:byte_message/byte_message.dart';
import 'package:byte_message/src/utils/byte_packing.dart';
import 'package:byte_message/src/protocols/layer3/dfu/dfu_blob.dart';

void main() {
  group('Layer3 DFU: Start/Finish Upgrade', () {
    test('StartUpgradeRes.fromBytes parses version and status', () {
      final res = StartUpgradeRes.fromBytes(const [0x01, 0x00]);
      expect(res.dfuPkgVersion, equals(0x01));
      expect(res.dfuOpResult, equals(0x00));
    });

    test('FinishUpgradeRes.fromBytes parses version and status', () {
      final res = FinishUpgradeRes.fromBytes(const [0x02, 0x01]);
      expect(res.dfuPkgVersion, equals(0x02));
      expect(res.dfuOpResult, equals(0x01));
    });
  });

  group('Layer3 DFU: WriteUpgradeChunk', () {
    test('DfuBlob.encode writes header fields in BE order and payload', () {
      final blob = DfuBlob(
        pageId: 0x0102,
        blobId: 0x0304,
        blobStart: 0x0008,
        blobData: const [0xAA, 0xBB, 0xCC],
      );

      final encoded = blob.encode();

      // 头部 8 字节：pageId | blobId | blobSize | blobStart（均为 BE）
      expect(encoded.sublist(0, 2), equals(packU16BE(0x0102)));
      expect(encoded.sublist(2, 4), equals(packU16BE(0x0304)));
      expect(encoded.sublist(4, 6), equals(packU16BE(3))); // blobSize = 3
      expect(encoded.sublist(6, 8), equals(packU16BE(0x0008)));

      // 载荷尾部为 blobData
      expect(encoded.sublist(8), equals(const [0xAA, 0xBB, 0xCC]));
    });

    test('WriteUpgradeChunkRes.fromBytes parses version and status enum', () {
      final res = WriteUpgradeChunkRes.fromBytes(const [0x01, 0x00]);
      expect(res.dfuPkgVersion, equals(0x01));
      expect(res.result, WriteUpgradeChunkResStatus.ok);
    });
  });

  group('Layer3 DFU: Negative cases for payload length and enums', () {
    test('StartUpgradeRes.fromBytes throws on invalid payload length', () {
      expect(() => StartUpgradeRes.fromBytes(const [0x01]),
          throwsA(isA<ArgumentError>()));
      expect(() => StartUpgradeRes.fromBytes(const [0x01, 0x00, 0x02]),
          throwsA(isA<ArgumentError>()));
    });

    test('FinishUpgradeRes.fromBytes throws on invalid payload length', () {
      expect(() => FinishUpgradeRes.fromBytes(const [0x02]),
          throwsA(isA<ArgumentError>()));
      expect(() => FinishUpgradeRes.fromBytes(const [0x02, 0x01, 0x03]),
          throwsA(isA<ArgumentError>()));
    });

    test('WriteUpgradeChunkRes.fromBytes throws on invalid payload length', () {
      expect(() => WriteUpgradeChunkRes.fromBytes(const [0x01]),
          throwsA(isA<ArgumentError>()));
      expect(() => WriteUpgradeChunkRes.fromBytes(const [0x01, 0x00, 0xFF]),
          throwsA(isA<ArgumentError>()));
    });

    test('WriteUpgradeChunkResStatus.fromValue throws on unknown value', () {
      expect(() => WriteUpgradeChunkResStatus.fromValue(0xFF),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('Layer3 DFU: GetDeviceInfoRes parsing', () {
    test('GetDeviceInfoRes.fromBytes parses all fields correctly (length 33)',
        () {
      // 构造 33 字节负载，所有字段均为 BE
      final payload = <int>[
        // DfuPkgVersion u8
        0x01,
        // BootloaderVersion u16
        0x00, 0x02,
        // BootloaderPageCnt u16
        0x00, 0x03,
        // DeviceType u16
        0x01, 0x04,
        // PageNum u32
        0x00, 0x00, 0x00, 0x05,
        // PageSize u32
        0x00, 0x00, 0x10, 0x00,
        // RomVersion u32 -> [b0,b1,b2,b3] => 2.3.04
        0x00, 0x02, 0x03, 0x04,
        // VenderInfo u32
        0x00, 0x00, 0x00, 0x06,
        // HardwareVersion u16
        0x00, 0x07,
        // DfuDeviceFlag u32
        0x00, 0x00, 0x00, 0x08,
        // DfuDevicePowerVolt u32
        0x00, 0x00, 0x12, 0x34,
      ];

      final res = GetDeviceInfoRes.fromBytes(payload);

      expect(res.dfuPkgVersion, equals(const [0x01]));
      expect(res.bootloaderVersion, equals(const [0x00, 0x02]));
      expect(res.bootloaderPageCnt, equals(const [0x00, 0x03]));
      expect(res.deviceType, equals(const [0x01, 0x04]));
      expect(res.pageNum, equals(const [0x00, 0x00, 0x00, 0x05]));
      expect(res.pageSize, equals(const [0x00, 0x00, 0x10, 0x00]));
      expect(res.romVersion, equals('2.3.04'));
      expect(res.venderInfo, equals(const [0x00, 0x00, 0x00, 0x06]));
      expect(res.hardwareVersion, equals(const [0x00, 0x07]));
      expect(res.dfuDeviceFlag, equals(const [0x00, 0x00, 0x00, 0x08]));
      expect(res.dfuDevicePowerVolt, equals(const [0x00, 0x00, 0x12, 0x34]));
    });

    test('GetDeviceInfoRes.fromBytes throws on invalid payload length', () {
      expect(() => GetDeviceInfoRes.fromBytes(const []),
          throwsA(isA<ArgumentError>()));
      expect(() => GetDeviceInfoRes.fromBytes(List<int>.filled(32, 0x01)),
          throwsA(isA<ArgumentError>()));
      expect(() => GetDeviceInfoRes.fromBytes(List<int>.filled(34, 0x01)),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('Layer3 DFU: WriteUpgradeBulk', () {
    test('DfuBlobList.encode writes blobCnt and multiple blobs', () {
      final blob1 = DfuBlob(
        pageId: 0x0102,
        blobId: 0x0304,
        blobStart: 0x0008,
        blobData: const [0xAA],
      );
      final blob2 = DfuBlob(
        pageId: 0x0203,
        blobId: 0x0405,
        blobStart: 0x0009,
        blobData: const [0xBB],
      );

      final blobList = DfuBlobList(blobs: [blob1, blob2]);
      final encoded = blobList.encode();

      expect(encoded[0], equals(2)); // BlobCnt
      // Blob 1 (len: 2+2+2+2+1 = 9)
      expect(encoded.sublist(1, 10), equals(blob1.encode()));
      // Blob 2
      expect(encoded.sublist(10), equals(blob2.encode()));
    });

    test('WriteUpgradeBulkRes.fromBytes parses version and status enum', () {
      final res = WriteUpgradeBulkRes.fromBytes(const [0x01, 0x00]);
      expect(res.dfuPkgVersion, equals(0x01));
      expect(res.result, WriteUpgradeBulkResStatus.ok);
    });

    test('WriteUpgradeBulkRes.fromBytes throws on invalid payload length', () {
      expect(() => WriteUpgradeBulkRes.fromBytes(const [0x01]),
          throwsA(isA<ArgumentError>()));
      expect(() => WriteUpgradeBulkRes.fromBytes(const [0x01, 0x00, 0xFF]),
          throwsA(isA<ArgumentError>()));
    });
  });
}
