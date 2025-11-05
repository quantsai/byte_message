/// DFU 第三层协议：开始升级（Start Upgrade）
///
/// 文档参考：byte_message.md#L214-227
/// - 请求：DfuCmd=0x02，DfuVersion=0x01，第三层请求负载为空（无数据）。
/// - 应答：AckOK 的第三层负载：
///   DfuPkgVersion u8,
///   DfuOpResult u8（0x00 表示 OK）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / DfuCmd / DfuVersion 等二/一层字段）。
library byte_message.l3.dfu.start_upgrade;

/// 开始升级请求（第三层）
///
/// 第三层请求负载为空，DFU 二层会携带 DfuCmd=0x02 与 DfuVersion=0x01。
class StartUpgradeReq {
  /// 生成第三层请求负载（空内容）
  ///
  /// 返回：
  /// - List<int> 空数组（[]），表示第三层无负载内容。
  List<int> encode() => const [];
}

/// 开始升级应答（第三层）
///
/// 负责解析“开始升级”请求的第三层应答负载：
/// - DfuPkgVersion u8 -> 格式化为字符串版本号 "MAJOR.MINOR.REVISION"（以 <value>.0.0 表示）
/// - DfuOpResult u8（0x00 表示 OK）
class StartUpgradeRes {
  /// DFU 包版本（字符串版本号：MAJOR.MINOR.REVISION，由 u8 派生）
  final int dfuPkgVersion;

  /// DFU 操作结果码（u8），0x00 表示 OK
  final int dfuOpResult;

  /// 构造函数
  StartUpgradeRes({
    required this.dfuPkgVersion,
    required this.dfuOpResult,
  });

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含一层/二层字段），总长度必须为 2 字节。
  ///
  /// 返回：
  /// - [StartUpgradeRes] 解析后的应答数据模型
  ///
  /// 异常：
  /// - [ArgumentError] 当长度不为 2 或字节不足时抛出
  static StartUpgradeRes fromBytes(List<int> bytes) {
    const expectedLength = 2;
    if (bytes.length != expectedLength) {
      throw ArgumentError(
        'Invalid DFU start upgrade payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    // 切片字节
    final dfuPkgVersionBytes = bytes.sublist(0, 1);
    final dfuOpResultBytes = bytes.sublist(1, 2);

    // 转换
    final dfuPkgVersion = dfuPkgVersionBytes[0] & 0xFF;
    final dfuOpResult = dfuOpResultBytes[0] & 0xFF;

    return StartUpgradeRes(
      dfuPkgVersion: dfuPkgVersion,
      dfuOpResult: dfuOpResult,
    );
  }

  @override
  String toString() {
    return 'StartUpgradeRes(dfuPkgVersion="$dfuPkgVersion", dfuOpResult=0x${dfuOpResult.toRadixString(16)})';
  }
}
