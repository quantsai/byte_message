/// ControlBus 第三层子命令（CbCmd）常量
///
/// 说明：统一维护 Control Bus 的第三层“子命令编号”，便于在工厂、协议实现、示例中复用，
/// 并减少散落常量导致的维护成本与一致性问题。
library;

class CbCmd {
  CbCmd._();

  /// 连接请求（Device Connection Request）
  /// CbCmd = 0x10
  static const int connectionRequest = 0x10;

  /// 电量与充电状态请求（Battery Status Request）
  /// CbCmd = 0x30
  static const int batteryStatusRequest = 0x30;

  /// 电压与电流请求（Electrical Metrics / Voltage & Current Request）
  /// CbCmd = 0x36
  static const int electricalMetricsRequest = 0x36;

  /// 机器状态请求（Device Status Request）
  /// CbCmd = 0x37
  static const int deviceStatusRequest = 0x37;

  /// 功能模式请求（Operating Mode Request）
  /// CbCmd = 0x3D
  static const int operatingModeRequest = 0x3D;

  /// 速度档位请求（Speed Gear Request）
  /// CbCmd = 0x3E
  static const int speedGearRequest = 0x3E;

  /// 速度控制请求（Speed Control Request）
  /// CbCmd = 0x41
  static const int speedControlRequest = 0x41;
}
