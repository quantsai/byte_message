/// 设置静音状态（Set Mute Status）第三层协议
///
/// - CbCmd: 0x84 （静音控制）
/// - 请求负载：静音状态（u8：0x00 关闭，0x01 开启），使用 MuteState 枚举
/// - 应答负载：无（Ack-only）
library byte_message.l3.control_bus.set_mute_status;

import 'package:byte_message/src/protocols/layer3/control_bus/get_mute_status.dart';

/// 设置静音状态请求（SetMuteStatusReq）
class SetMuteStatusReq {
  /// 静音状态（使用 MuteState 枚举）
  final MuteState state;

  /// 构造函数
  const SetMuteStatusReq({required this.state});

  /// 编码为字节数组（仅 1 字节的 u8 状态值）
  ///
  /// 参数：无（使用成员变量 [state]）
  /// 返回：请求负载字节数组（长度 1）
  List<int> encode() {
    return [state.value & 0xFF];
  }
}

/// 设置静音状态应答（SetMuteStatusAck）
///
/// 此应答无负载，工厂在解码时仅校验 AckOK 与负载为空
class SetMuteStatusAck {
  /// 构造函数（空负载应答）
  const SetMuteStatusAck();
}