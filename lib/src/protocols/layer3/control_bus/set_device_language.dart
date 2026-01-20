/// 设置设备语言（Set Device Language）第三层协议
///
/// - CbCmd: 0x83 （设备语言控制）
/// - 请求负载：语言（u8，使用 DeviceLanguage 枚举的值 0x01/0x02）
/// - 应答负载：无（Ack-only）
library byte_message.l3.control_bus.set_device_language;

import 'package:byte_message/src/protocols/layer3/control_bus/get_device_language.dart';

/// 设置设备语言请求（SetDeviceLanguageReq）
class SetDeviceLanguageReq {
  /// 设备语言（使用 DeviceLanguage 枚举）
  final DeviceLanguage language;

  /// 构造函数
  const SetDeviceLanguageReq({required this.language});

  /// 编码为字节数组（仅 1 字节的 u8 语言值）
  ///
  /// 参数：无（使用成员变量 [language]）
  /// 返回：请求负载字节数组（长度 1）
  List<int> encode() {
    return [language.value & 0xFF];
  }
}

/// 设置设备语言应答（SetDeviceLanguageAck）
///
/// 此应答无负载，工厂在解码时仅校验 AckOK 与负载为空
class SetDeviceLanguageAck {
  /// 构造函数（空负载应答）
  const SetDeviceLanguageAck();
}
