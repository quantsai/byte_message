/// 控制总线第三层协议：机器状态（Device Status）
///
/// 文档参考：control.md#L126-145
/// - 请求：指令编号 0x37，第三层请求负载为空（无数据）。
/// - 应答：机器状态 u8，错误码 u32（均为大端序，错误码为无符号32位）。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / CbCmd 等字段）。
library byte_message.l3.control_bus.device_status;

import 'package:byte_message/src/utils/byte_packing.dart';

/// 机器状态请求（第三层）
///
/// 负责生成“机器状态”请求的第三层负载字节。
/// 注意：该请求在第三层无负载（空数组）。
class GetDeviceStatusReq {
  /// 生成第三层请求负载（空内容）
  ///
  /// 返回：
  /// - List<int> 空数组（[]），表示第三层无负载内容。
  List<int> encode() {
    return const [];
  }
}

/// 机器状态应答（第三层）
///
/// 负责解析“机器状态”请求的第三层应答负载：机器状态（u8）与错误码（u32 BE）。
class GetDeviceStatusRes {
  /// 机器状态（u8）
  final DeviceStatus deviceStatus;

  /// 错误码（u32，无符号，BE）
  final int errorCode;

  /// 构造函数
  ///
  /// 参数：
  /// - [deviceStatus] 机器状态（u8）
  /// - [errorCode] 错误码（u32 BE，无符号）
  GetDeviceStatusRes({required this.deviceStatus, required this.errorCode});

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含第一层/第二层字段），总长度必须为 5 字节：
  ///   第 0 字节为机器状态（u8），第 1..4 字节为错误码（u32 BE）。
  ///
  /// 返回：
  /// - [GetDeviceStatusRes] 解析后的应答数据模型
  ///
  /// 异常：
  /// - [ArgumentError] 当长度不为 5 或字节不足时抛出
  static GetDeviceStatusRes fromBytes(List<int> bytes) {
    const expectedLength = 5;
    if (bytes.length < expectedLength) {
      throw ArgumentError(
        'Invalid device status payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    final statusByte = bytes[0] & 0xFF; // u8
    final deviceStatus = DeviceStatus.fromValue(statusByte); // 解析枚举值
    final error = readU32BE(bytes.sublist(1, 5)); // u32 BE

    return GetDeviceStatusRes(deviceStatus: deviceStatus, errorCode: error);
  }

  @override
  String toString() {
    return 'GetDeviceStatusRes(deviceStatus=$deviceStatus, errorCode=$errorCode)';
  }
}

enum DeviceStatus {
  /// 未知
  unknown(0xFF);

  final int value;

  const DeviceStatus(this.value);
  // 从value获取枚举值
  static DeviceStatus fromValue(int value) => DeviceStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => DeviceStatus.unknown,
      );
}
