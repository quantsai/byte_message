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

import 'package:byte_message/src/protocols/layer3/dfu/dfu_blob.dart';

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
