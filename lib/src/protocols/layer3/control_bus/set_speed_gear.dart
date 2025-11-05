/// 设置速度档位（Set Speed Gear）第三层协议
///
/// - CbCmd: 0x4E （速度档位控制）
/// - 请求负载：档位（u8）
/// - 应答负载：无（Ack-only）
library byte_message.l3.control_bus.set_speed_gear;

import 'package:byte_message/src/protocols/layer3/control_bus/speed_gear.dart';

/// 设置速度档位请求（SetSpeedGearReq）
class SetSpeedGearReq {
  /// 速度档位（使用 SpeedGear 枚举）
  final SpeedGear gear;

  /// 构造函数
  const SetSpeedGearReq({required this.gear});

  /// 编码为字节数组（仅 1 字节的 u8 档位值）
  ///
  /// 参数：无（使用成员变量 [gear]）
  /// 返回：请求负载字节数组（长度 1）
  List<int> encode() {
    return [gear.value & 0xFF];
  }
}

/// 设置速度档位应答（SetSpeedGearAck）
///
/// 此应答无负载，工厂在解码时仅校验 AckOK 与负载为空
class SetSpeedGearAck {
  /// 构造函数（空负载应答）
  const SetSpeedGearAck();
}