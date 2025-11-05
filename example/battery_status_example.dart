import 'package:byte_message/byte_message.dart';

/// 示例：第三层电量与充电状态请求/应答的编码与解码
///
/// 功能说明：
/// - 生成第三层“电量与充电状态请求”的负载字节（空数组，第三层无负载）。
/// - 构造一个模拟的第三层“电量与充电状态应答”负载（2 字节：电量百分比 u8 + 充电状态 u8）。
/// - 使用 BatteryStatusRes.fromBytes 解析，并读取便捷属性 isCharging / isPluggedIn。
///
/// 参数：无
/// 返回：无（示例程序仅打印解析结果）
void main() {
  // 1) 生成第三层“电量与充电状态请求”的负载字节
  final req = BatteryStatusReq();
  final reqPayload = req.encode();
  print('Layer3 BatteryStatusReq Payload: $reqPayload'); // []

  // 2) 构造一个模拟的第三层“电量与充电状态应答”的负载
  // 字节布局：
  //   [0] batteryPercent: 电量百分比（u8，0..100）
  //   [1] chargeStatus: 充电状态（u8，按位定义）
  // 按位定义（参考 control.md 规范）：
  //   bit0 -> 是否正在充电（isCharging）
  //   bit1 -> 是否插电（isPluggedIn）
  //   bit2..5 -> 文档标注为暂不使用/废弃位（原样保留）
  //   bit6..7 -> 预留位

  final batteryPercent = 85; // 85%
  final chargeStatus = 0x03; // bit0=1(充电中), bit1=1(已插电)
  final resPayload = <int>[batteryPercent, chargeStatus];

  // 3) 解析第三层应答
  final res = BatteryStatusRes.fromBytes(resPayload);
  print('Battery Percent: ${res.batteryPercent}%');
  print('Battery status: ${res.chargeStatus}');
}
