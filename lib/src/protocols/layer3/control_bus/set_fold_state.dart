/// 控制总线第三层协议：折叠/展开控制（Set Fold State）
///
/// 文档参考：control.md#L292-310
/// - 请求：指令编号 0x82，第三层负载为 1 字节（u8）：0x00 折叠，0x01 展开。
/// - 应答：无第三层负载（Ack-only）。
library byte_message.l3.control_bus.set_fold_state;

import 'package:byte_message/src/utils/validation.dart';

/// 折叠/展开枚举
///
/// - fold：0x00（折叠）
/// - unfold：0x01（展开）
enum FoldState {
  fold(0x00),
  unfold(0x01);

  /// 对应的 u8 值
  final int value;
  const FoldState(this.value);

  /// 将 u8 映射为枚举值
  ///
  /// 参数：
  /// - [v] u8（0..255）
  /// 返回：FoldState
  /// 异常：当 v 不是 0x00 或 0x01 时抛出 ArgumentError
  static FoldState fromValue(int v) {
    ensureU8(v, name: 'FoldState');
    for (final s in FoldState.values) {
      if (s.value == v) return s;
    }
    throw ArgumentError('Invalid FoldState u8 value: 0x${v.toRadixString(16)}');
  }
}

/// 第三层：设置折叠/展开请求
class SetFoldStateReq {
  /// 折叠/展开枚举值
  final FoldState state;

  /// 构造函数
  ///
  /// 参数：
  /// - [state] 折叠/展开枚举
  const SetFoldStateReq({required this.state});

  /// 编码第三层请求负载
  ///
  /// 功能：将枚举值编码为一个 u8 字节（0x00 折叠 / 0x01 展开）。
  /// 参数：无
  /// 返回：List<int> [state]
  List<int> encode() {
    final v = state.value & 0xFF;
    ensureU8(v, name: 'FoldState');
    return [v];
  }
}

/// 第三层：设置折叠/展开应答（无负载）
class SetFoldStateAck {
  /// 构造函数（空负载应答）
  const SetFoldStateAck();
}
