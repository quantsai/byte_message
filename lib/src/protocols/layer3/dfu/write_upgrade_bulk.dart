/// DFU 第三层协议：批量写升级包（Write Upgrade Bulk）
///
/// 文档参考：byte_message.md#L261-280
/// - 请求：DfuCmd=0x07，DfuVersion=0x01，第三层请求负载为 DfuBlobList。
/// - 应答：AckOK 的第三层负载：
///   DfuPkgVersion u8,
///   DfuOpResult u8（0x00 表示 OK，0x01 表示 Incompatible）。
library byte_message.l3.dfu.write_upgrade_bulk;

import 'package:byte_message/src/protocols/layer3/dfu/dfu_blob.dart';

/// DfuBlobList 数据结构（第三层）
///
/// 字段：
/// - BlobCnt u8
/// - DfuBlob * n
class DfuBlobList {
  /// Blob 数量 (u8)
  final int blobCnt;

  /// Blob 列表
  final List<DfuBlob> blobs;

  /// 构造函数
  DfuBlobList({required this.blobs}) : blobCnt = blobs.length {
    if (blobCnt > 0xFF) {
      throw RangeError.value(blobCnt, 'blobCnt', 'Must be u8 (<= 255)');
    }
  }

  /// 编码为第三层负载字节
  List<int> encode() {
    final out = <int>[];
    out.add(blobCnt);
    for (final blob in blobs) {
      out.addAll(blob.encode());
    }
    return out;
  }
}

/// 批量写升级包请求（第三层）
class WriteUpgradeBulkReq {
  /// DfuBlobList 数据
  final DfuBlobList blobList;

  /// 构造函数
  WriteUpgradeBulkReq({required this.blobList});

  /// 生成第三层请求负载
  List<int> encode() => blobList.encode();
}

/// 批量写升级包应答（第三层）
///
/// 负责解析“批量写升级包”请求的第三层应答负载：
/// - DfuPkgVersion u8
/// - DfuOpResult u8（0x00 表示 OK，0x01 表示 Incompatible）
class WriteUpgradeBulkRes {
  /// DFU 包版本（u8 原始值）
  final int dfuPkgVersion;

  /// DFU 操作结果码（u8）
  final WriteUpgradeBulkResStatus result;

  /// 构造函数
  WriteUpgradeBulkRes({
    required this.dfuPkgVersion,
    required this.result,
  });

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含一层/二层字段），总长度必须为 2 字节。
  static WriteUpgradeBulkRes fromBytes(List<int> bytes) {
    const expectedLength = 2;
    if (bytes.length != expectedLength) {
      throw ArgumentError(
        'Invalid DFU write upgrade bulk payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    // 切片字节
    final dfuPkgVersion = bytes[0] & 0xFF;
    final dfuOpResult = bytes[1] & 0xFF;

    return WriteUpgradeBulkRes(
      dfuPkgVersion: dfuPkgVersion,
      result: WriteUpgradeBulkResStatus.fromValue(dfuOpResult),
    );
  }

  @override
  String toString() {
    return 'WriteUpgradeBulkRes(dfuPkgVersion="$dfuPkgVersion", dfuOpResult=${result.value})';
  }
}

/// 批量写升级包响应状态
enum WriteUpgradeBulkResStatus {
  ok(0x00),
  incompatible(0x01);

  final int value;
  const WriteUpgradeBulkResStatus(this.value);

  static WriteUpgradeBulkResStatus fromValue(int value) {
    return WriteUpgradeBulkResStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError(
          'No WriteUpgradeBulkResStatus found for value $value'),
    );
  }
}
