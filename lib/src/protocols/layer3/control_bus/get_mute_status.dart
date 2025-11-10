/// 控制总线第三层协议：静音状态（Mute Status）
///
/// 文档参考：control.md（新增：获取静音状态）
/// - 请求：指令编号 0x86，第三层请求负载为空（无数据）。
/// - 应答：静音状态 u8（0x00 关闭，0x01 开启）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.mute_status;

import 'package:byte_message/src/utils/validation.dart';

/// 静音状态枚举
///
/// 定义：
/// - off：0x00（关闭）
/// - on：0x01（开启）
enum MuteState {
  off(0x00),
  on(0x01);

  /// 对应的 u8 值
  final int value;
  const MuteState(this.value);

  /// 将 u8 映射为枚举值
  ///
  /// 参数：
  /// - v：u8 状态码（0..255）
  /// 返回：MuteState 对应枚举
  /// 异常：当 v 不在 0x00..0x01 范围内时抛出 ArgumentError
  static MuteState fromValue(int v) {
    ensureU8(v, name: 'MuteState');
    for (final s in MuteState.values) {
      if (s.value == v) return s;
    }
    throw ArgumentError('Invalid MuteState u8 value: 0x${v.toRadixString(16)}');
  }
}

/// 第三层：获取静音状态请求
class GetMuteStatusReq {
  /// 编码第三层请求负载
  ///
  /// 功能：静音状态请求在第三层无负载，返回空数组。
  /// 参数：无
  /// 返回：List<int> 空数组 []
  List<int> encode() {
    return const <int>[];
  }
}

/// 第三层：获取静音状态应答
class GetMuteStatusRes {
  /// 静音状态枚举
  final MuteState state;

  /// 构造函数
  ///
  /// 参数：
  /// - state：静音状态枚举
  const GetMuteStatusRes({required this.state});

  /// 从第三层字节数组解析静音状态应答
  ///
  /// 功能：解析长度为 1 的载荷，返回 GetMuteStatusRes。
  /// 参数：
  /// - bytes：第三层载荷，必须仅包含 1 字节（u8 状态码）。
  /// 返回：GetMuteStatusRes
  /// 异常：
  /// - ArgumentError：当载荷长度不是 1 或状态值不在 0x00..0x01 时抛出。
  static GetMuteStatusRes fromBytes(List<int> bytes) {
    if (bytes.length != 1) {
      throw ArgumentError(
        'Invalid L3 mute status payload length: expected 1, got ${bytes.length}',
      );
    }
    final v = bytes[0] & 0xFF; // u8
    final state = MuteState.fromValue(v);
    return GetMuteStatusRes(state: state);
  }

  @override
  String toString() =>
      'GetMuteStatusRes{state: ${state.name}(0x${state.value.toRadixString(16)})}';
}