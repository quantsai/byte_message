/// 设置操作模式（Set Operating Mode）第三层协议
///
/// - CbCmd: 0x4D （功能模式控制）
/// - 请求负载：模式值（u8）
/// - 应答负载：无（Ack-only）
library byte_message.l3.control_bus.set_operating_mode;

import 'package:byte_message/src/protocols/layer3/control_bus/get_operating_mode.dart';

/// 设置操作模式请求（SetOperatingModeReq）
class SetOperatingModeReq {
  /// 操作模式（使用 OperatingMode 枚举）
  final OperatingMode mode;

  /// 构造函数
  const SetOperatingModeReq({required this.mode});

  /// 编码为字节数组（仅 1 字节的 u8 模式值）
  ///
  /// 参数：无（使用成员变量 [mode]）
  /// 返回：请求负载字节数组（长度 1）
  List<int> encode() {
    return [mode.value & 0xFF];
  }
}

/// 设置操作模式应答（SetOperatingModeAck）
///
/// 此应答无负载，工厂在解码时仅校验 AckOK 与负载为空
class SetOperatingModeAck {
  /// 构造函数（空负载应答）
  const SetOperatingModeAck();
}
