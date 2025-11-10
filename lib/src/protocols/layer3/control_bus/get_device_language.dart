/// 控制总线第三层协议：设备语言（Device Language）
///
/// 文档参考：control.md（新增：获取设备语言）
/// - 请求：指令编号 0x85，第三层请求负载为空（无数据）。
/// - 应答：语言代码 u8（0x01 中文，0x02 英文）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.device_language;

import 'package:byte_message/src/utils/validation.dart';

/// 设备语言枚举
///
/// 定义：
/// - chinese：0x01（中文）
/// - english：0x02（英文）
enum DeviceLanguage {
  chinese(0x01),
  english(0x02);

  /// 对应的 u8 值
  final int value;
  const DeviceLanguage(this.value);

  /// 将 u8 映射为枚举值
  ///
  /// 参数：
  /// - v：u8 语言代码（0..255）
  /// 返回：DeviceLanguage 对应枚举
  /// 异常：当 v 不在 0x01..0x02 范围内时抛出 ArgumentError
  static DeviceLanguage fromValue(int v) {
    ensureU8(v, name: 'DeviceLanguage');
    for (final g in DeviceLanguage.values) {
      if (g.value == v) return g;
    }
    throw ArgumentError(
        'Invalid DeviceLanguage u8 value: 0x${v.toRadixString(16)}');
  }
}

/// 第三层：获取设备语言请求
class GetDeviceLanguageReq {
  /// 编码第三层请求负载
  ///
  /// 功能：设备语言请求在第三层无负载，返回空数组。
  /// 参数：无
  /// 返回：List<int> 空数组 []
  List<int> encode() {
    return const <int>[];
  }
}

/// 第三层：获取设备语言应答
class GetDeviceLanguageRes {
  /// 语言枚举
  final DeviceLanguage language;

  /// 构造函数
  ///
  /// 参数：
  /// - language：设备语言枚举
  const GetDeviceLanguageRes({required this.language});

  /// 从第三层字节数组解析设备语言应答
  ///
  /// 功能：解析长度为 1 的载荷，返回 GetDeviceLanguageRes。
  /// 参数：
  /// - bytes：第三层载荷，必须仅包含 1 字节（u8 语言代码）。
  /// 返回：GetDeviceLanguageRes
  /// 异常：
  /// - ArgumentError：当载荷长度不是 1 或语言值不在 0x01..0x02 时抛出。
  static GetDeviceLanguageRes fromBytes(List<int> bytes) {
    if (bytes.length != 1) {
      throw ArgumentError(
        'Invalid L3 device language payload length: expected 1, got ${bytes.length}',
      );
    }
    final v = bytes[0] & 0xFF; // u8
    final lang = DeviceLanguage.fromValue(v);
    return GetDeviceLanguageRes(language: lang);
  }

  @override
  String toString() =>
      'GetDeviceLanguageRes{language: ${language.name}(0x${language.value.toRadixString(16)})}';
}