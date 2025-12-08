/// ControlBus 第三层子命令（CbCmd）
///
/// 说明：采用 Dart 增强枚举管理 Control Bus 的第三层“子命令编号”，便于在工厂、协议实现、示例中复用，
/// 并提升类型安全与可维护性。
library;

/// CbCmd 增强枚举
///
/// 功能描述：统一、类型安全地表示 Control Bus 第三层子命令，并保留与协议的字节码映射。
/// 参数说明：枚举构造参数为协议字节码（code，u8）。
/// 返回值用途：提供 fromCode 工厂用于从字节还原枚举。
enum CbCmd {
  /// 连接请求（Device Connection Request）
  connectionRequest(0x10),

  /// 电量与充电状态请求（Battery Status Request）
  batteryStatusRequest(0x30),

  /// 电压与电流请求（Electrical Metrics / Voltage & Current Request）
  electricalMetricsRequest(0x36),

  /// 机器状态请求（Device Status Request）
  deviceStatusRequest(0x37),

  /// 功能模式请求（Operating Mode Request）
  operatingModeRequest(0x3D),

  /// 速度档位请求（Speed Gear Request）
  speedGearRequest(0x3E),

  /// 速度控制请求（Speed Control Request）
  speedControlRequest(0x41),

  /// 推杆速度设置请求（Push Rod Control / Set PushRod Speed Request）
  pushRodControlRequest(0x42),

  /// 功能模式控制请求（Operating Mode Control / Set Operating Mode Request）
  operatingModeControlRequest(0x4D),

  /// 速度档位控制请求（Speed Gear Control / Set Speed Gear Request）
  speedGearControlRequest(0x4E),

  /// 播放喇叭控制请求（Horn Control / Play Horn Request）
  ///
  /// 说明：第三层负载为时长（u16，毫秒，BE）。
  hornControlRequest(0x4F),

  /// 摇杆控制请求（Joystick Control / Set Joystick Request）
  joystickControlRequest(0x81),

  /// 折叠/展开控制请求（Fold/Unfold Control / Set Fold State Request）
  foldControlRequest(0x82),

  /// 设置设备语言请求（Set Device Language Control Request）
  deviceLanguageControlRequest(0x83),

  /// 设置静音状态请求（Mute Control / Set Mute Status Request）
  muteControlRequest(0x84),

  /// 设备语言请求（Device Language Request / Get Device Language）
  deviceLanguageRequest(0x85),

  /// 静音状态请求（Mute Status Request / Get Mute Status）
  muteStatusRequest(0x86);

  /// 对应协议字节码（u8）
  final int code;
  const CbCmd(this.code);

  /// 从协议字节码还原枚举；若未知则返回 null
  static CbCmd? fromCode(int code) {
    for (final v in CbCmd.values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
