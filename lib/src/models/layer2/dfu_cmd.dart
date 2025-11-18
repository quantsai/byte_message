/// DFU 子命令（DfuCmd）枚举
///
/// 说明：采用 Dart 增强枚举统一维护 DFU 的二层“子命令编号”，对应 byte_message.md 文档中的指令列表，
/// 用于升级流程（获取设备信息、开始/完成升级、运行、写入升级包等）。
library;

/// DfuCmd 增强枚举（含协议字节码 code）
enum DfuCmd {
  /// 获取设备信息（Get Device Info）
  getDeviceInfo(0x01),

  /// 开始升级（Start Upgrade）
  startUpgrade(0x02),

  /// 完成升级（Finish Upgrade）
  finishUpgrade(0x03),

  /// 运行（Run）
  run(0x04),

  /// 写升级包（Write Upgrade Chunk）
  writeUpgradeChunk(0x05),

  /// 批量写升级包（Write Upgrade Bulk）
  writeUpgradeBulk(0x07);

  /// 对应协议字节码（u8）
  final int code;
  const DfuCmd(this.code);

  /// 从协议字节码还原枚举；若未知则返回 null
  static DfuCmd? fromCode(int code) {
    for (final v in DfuCmd.values) {
      if (v.code == code) return v;
    }
    return null;
  }
}