/// DFU 第三层协议：写升级包（Write Upgrade Chunk）
///
/// 文档参考：byte_message.md#L242-261
/// - 请求：DfuCmd=0x05，DfuVersion=0x01，第三层请求负载为 DfuBlob。
/// - 应答：AckOK 的第三层负载：
///   DfuPkgVersion u8,
///   DfuOpResult u8（0x00 表示 OK，0x01 表示 Incompatible）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / DfuCmd / DfuVersion 等二/一层字段）。
library byte_message.l3.dfu.write_upgrade_chunk;

import 'package:byte_message/src/utils/byte_packing.dart';

/// DfuBlob 数据结构（第三层）
///
/// 字段（均为 BE 编码）：
/// - PageId u16
/// - BlobId u16
/// - BlobSize u16（由 BlobData.length 自动计算）
/// - BlobStart u16
/// - BlobData u8[n]
class DfuBlob {
  /// 页编号（u16）
  final int pageId;

  /// 片段编号（u16）
  final int blobId;

  /// 片段在页内起始偏移（u16）
  final int blobStart;

  /// 片段数据（u8[n]）
  final List<int> blobData;

  /// 片段大小（u16），由 blobData.length 自动计算
  int get blobSize => blobData.length;

  /// 构造函数
  ///
  /// 参数：
  /// - [pageId] 页编号（u16）
  /// - [blobId] 片段编号（u16）
  /// - [blobStart] 片段起始偏移（u16）
  /// - [blobData] 片段数据（u8[n]）
  DfuBlob({
    required this.pageId,
    required this.blobId,
    required this.blobStart,
    required List<int> blobData,
  }) : blobData = List<int>.from(blobData) {
    // 基础校验：确保各字段符合范围
    if (pageId < 0 || pageId > 0xFFFF) {
      throw RangeError.value(pageId, 'pageId', 'Must be u16');
    }
    if (blobId < 0 || blobId > 0xFFFF) {
      throw RangeError.value(blobId, 'blobId', 'Must be u16');
    }
    if (blobStart < 0 || blobStart > 0xFFFF) {
      throw RangeError.value(blobStart, 'blobStart', 'Must be u16');
    }
    if (blobData.length > 0xFFFF) {
      throw RangeError.value(
          blobData.length, 'blobData.length', 'BlobSize must fit u16');
    }
    for (final b in blobData) {
      if (b < 0 || b > 0xFF) {
        throw RangeError.value(b, 'blobData item', 'Must be u8');
      }
    }
  }

  /// 编码为第三层负载字节（BE）
  ///
  /// 返回：
  /// - List<int>：按顺序拼接 PageId/BlobId/BlobSize/BlobStart/BlobData
  List<int> encode() {
    final out = <int>[];
    out.addAll(packU16BE(pageId));
    out.addAll(packU16BE(blobId));
    out.addAll(packU16BE(blobSize));
    out.addAll(packU16BE(blobStart));
    out.addAll(blobData);
    return out;
  }
}

/// 写升级包请求（第三层）
///
/// 将 [DfuBlob] 作为第三层载荷进行编码。
class WriteUpgradeChunkReq {
  /// DfuBlob 数据
  final DfuBlob blob;

  /// 构造函数
  ///
  /// 参数：
  /// - [blob] 要写入的升级片段数据
  WriteUpgradeChunkReq({required this.blob});

  /// 生成第三层请求负载（DfuBlob 编码字节）
  ///
  /// 返回：
  /// - List<int>：第三层负载字节，包含 DfuBlob 所有字段。
  List<int> encode() => blob.encode();
}

/// 写升级包应答（第三层）
///
/// 负责解析“写升级包”请求的第三层应答负载：
/// - DfuPkgVersion u8
/// - DfuOpResult u8（0x00 表示 OK，0x01 表示 Incompatible）
class WriteUpgradeChunkRes {
  /// DFU 包版本（u8 原始值）
  final int dfuPkgVersion;

  /// DFU 操作结果码（u8）
  final WriteUpgradeChunkResStatus result;

  /// 构造函数
  WriteUpgradeChunkRes({
    required this.dfuPkgVersion,
    required this.result,
  });

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含一层/二层字段），总长度必须为 2 字节。
  ///
  /// 返回：
  /// - [WriteUpgradeChunkRes] 解析后的应答数据模型
  ///
  /// 异常：
  /// - [ArgumentError] 当长度不为 2 或字节不足时抛出
  static WriteUpgradeChunkRes fromBytes(List<int> bytes) {
    const expectedLength = 2;
    if (bytes.length != expectedLength) {
      throw ArgumentError(
        'Invalid DFU write upgrade chunk payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    // 切片字节
    final dfuPkgVersionBytes = bytes.sublist(0, 1);
    final dfuOpResultBytes = bytes.sublist(1, 2);

    // 转换
    final dfuPkgVersion = dfuPkgVersionBytes[0] & 0xFF;
    final result =
        WriteUpgradeChunkResStatus.fromValue(dfuOpResultBytes[0] & 0xFF);

    return WriteUpgradeChunkRes(
      dfuPkgVersion: dfuPkgVersion,
      result: result,
    );
  }

  @override
  String toString() {
    return 'WriteUpgradeChunkRes(dfuPkgVersion="$dfuPkgVersion", dfuOpResult=${result.value})';
  }
}

enum WriteUpgradeChunkResStatus {
  ok(0x00),
  incompatible(0x01);

  final int value;
  const WriteUpgradeChunkResStatus(this.value);

  static WriteUpgradeChunkResStatus fromValue(int value) {
    return WriteUpgradeChunkResStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError(
          'No WriteUpgradeChunkResStatus found for value $value'),
    );
  }
}
