/// DFU 数据块定义（第三层）
///
/// 用于 WriteUpgradeChunk (0x05) 和 WriteUpgradeBulk (0x07) 命令。
library byte_message.l3.dfu.dfu_blob;

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
