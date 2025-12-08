/// 控制总线第三层协议：播放喇叭（Play Horn）
///
/// - CbCmd: 0x4F（播放喇叭控制请求）
/// - 请求负载：时长（u16，毫秒，BE）
/// - 应答负载：无（Ack-only）
library byte_message.l3.control_bus.play_horn;

import 'package:byte_message/src/utils/byte_packing.dart';

/// 第三层：播放喇叭请求（PlayHornReq）
class PlayHornReq {
  /// 播放时长（毫秒），范围 0..65535，对应 u16。
  final int durationMs;

  /// 构造函数
  ///
  /// 参数：
  /// - [durationMs] 播放时长（毫秒），必须在 0..65535 之间。
  const PlayHornReq({required this.durationMs});

  /// 编码第三层请求负载（u16 BE：时长毫秒数）
  ///
  /// 返回：长度 2 的字节数组 [high, low]（大端序）。
  /// 异常：当 [durationMs] 不在 0..65535 范围内时抛出 ArgumentError。
  List<int> encode() {
    if (durationMs < 0 || durationMs > 0xFFFF) {
      throw ArgumentError('PlayHornReq.durationMs out of range: $durationMs');
    }
    return packU16BE(durationMs);
  }
}

/// 第三层：播放喇叭应答（Ack）
///
/// 说明：该应答不携带第三层载荷，仅通过一层 Cmd=AckOK 表示成功。
class PlayHornAck {
  const PlayHornAck();

  /// 从第三层字节解析 Ack
  ///
  /// 功能：校验第三层载荷长度必须为 0。
  /// 参数：
  /// - [bytes] 第三层载荷字节数组。
  /// 返回：常量 Ack 对象用于表示成功。
  /// 异常：当载荷非空时抛出 ArgumentError。
  static PlayHornAck fromBytes(List<int> bytes) {
    if (bytes.isNotEmpty) {
      throw ArgumentError(
          'Invalid L3 play horn ack payload length: expected 0, got ${bytes.length}');
    }
    return const PlayHornAck();
  }
}

