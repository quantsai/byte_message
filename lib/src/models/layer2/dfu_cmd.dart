/// DFU 子命令（DfuCmd）常量
///
/// 说明：统一维护 DFU 的二层“子命令编号”，对应 byte_message.md 文档中的指令列表，
/// 用于升级流程（获取设备信息、开始/完成升级、运行、写入升级包等）。
library;

class DfuCmd {
  DfuCmd._();

  /// 获取设备信息（Get Device Info）
  /// 命令代码：0x01
  /// 描述：返回设备关于升级的一系列信息。
  static const int getDeviceInfo = 0x01;

  /// 开始升级（Start Upgrade）
  /// 命令代码：0x02
  /// 描述：初始化升级过程。
  static const int startUpgrade = 0x02;

  /// 完成升级（Finish Upgrade）
  /// 命令代码：0x03
  /// 描述：完成升级过程并进入 bootloader。
  static const int finishUpgrade = 0x03;

  /// 运行（Run）
  /// 命令代码：0x04
  /// 描述：结束 DFU 并运行应用（具体行为依设备定义）。
  static const int run = 0x04;

  /// 写升级包（Write Upgrade Chunk）
  /// 命令代码：0x05
  /// 描述：将一个片段写入 flash。
  static const int writeUpgradeChunk = 0x05;

  /// 批量写升级包（Write Upgrade Bulk）
  /// 命令代码：0x07
  /// 描述：批量写入 flash。
  static const int writeUpgradeBulk = 0x07;
}