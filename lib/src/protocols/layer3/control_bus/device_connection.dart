/// 控制总线第三层协议：请求连接（Connection Request）
///
/// 本文件实现第三层协议的两部分：
/// - 请求编码：根据协议版本生成第三层请求字节序列（仅第三层内容，不含第一层/第二层字段）
/// - 应答解码：从第三层字节序列解析出型号、固件版本、硬件版本与序列号（不处理第一层/第二层字段）
///
/// 设计约束：
/// - 与前两层完全解耦：不包含 Cmd / CbCmd / DfuCmd 等字段，仅处理第三层的内容字节
/// - 调用方负责在更高一层组帧（将第三层字节放入第二层/第一层载荷）
library byte_message.l3.control_bus.connection_protocol;

import 'package:byte_message/src/utils/validation.dart';
import 'package:byte_message/src/utils/byte_packing.dart';

/// 设备连接请求（第三层）
///
/// 负责生成“请求连接”的第三层负载字节（与前两层解耦）
class DeviceConnectionReq {
  /// 第三层协议的协议版本（u8），默认 0x02（TT01 协议版本）
  final int protocolVersion;

  /// 构造函数
  ///
  /// 参数：
  /// - [protocolVersion] 协议版本（u8），默认 0x02
  ///
  /// 异常：
  /// - [RangeError] 当 protocolVersion 超出 u8 范围（0..255）时抛出
  DeviceConnectionReq({this.protocolVersion = 0x02}) {
    // 校验协议版本为 u8 范围
    ensureU8(protocolVersion, name: 'protocolVersion');
  }

  /// 生成第三层请求连接负载字节
  ///
  /// 返回：
  /// - List<int> 仅包含第三层负载内容（不含第一层/第二层字段），格式为：[protocolVersion]
  List<int> encode() {
    return [protocolVersion];
  }
}

/// 设备连接应答（第三层）
///
/// 负责解析“请求连接”的第三层应答负载（与前两层解耦）
class DeviceConnectionRes {
  /// 型号字符串（由 u8[12] ASCII 字节转换，并去除结尾 0x00 填充）
  final String model;

  /// 固件版本字符串（由 u16 值按 MAJOR.MINOR.REVISION 规则转换，大端）
  final String firmwareVersion;

  /// 硬件版本字符串（由 u16 值按 MAJOR.MINOR.REVISION 规则转换，大端）
  final String hardwareVersion;

  /// 序列号字符串（3 个 u32 段（大端）的十进制拼接）
  final String serialNumber;

  /// 构造函数
  ///
  /// 参数：
  /// - [modelBytes] 长度应为 12 的字节数组
  /// - [firmwareVersion] 固件版本（0..65535）
  /// - [hardwareVersion] 硬件版本（0..65535）
  /// - [serialNumberSegments] 长度应为 3 的列表，每个元素为 u32（0..4294967295）
  DeviceConnectionRes({
    required this.model,
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.serialNumber,
  });

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含第一层/第二层字段），总长度必须为 28 字节：
  ///   12（型号） + 2（固件版本） + 2（硬件版本） + 4*3（序列号三段）
  ///
  /// 返回：
  /// - [ControlBusConnectionResponse] 解析后的应答数据模型
  ///
  /// 异常：
  /// - [ArgumentError] 当长度不为 28 或字节不足时抛出
  static DeviceConnectionRes fromBytes(List<int> bytes) {
    const expectedLength = 12 + 2 + 2 + 4 * 3; // 28
    if (bytes.length != expectedLength) {
      throw ArgumentError(
        'Invalid response payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    // 解析各字段（小端序）
    final modelBytes = bytes.sublist(0, 12);

    final fwBytes = readU16BE(bytes.sublist(12, 14));
    final hwBytes = readU16BE(bytes.sublist(14, 16));
    final sn1Bytes = readU32BE(bytes.sublist(16, 20));
    final sn2Bytes = readU32BE(bytes.sublist(20, 24));
    final sn3Bytes = readU32BE(bytes.sublist(24, 28));

    /// 型号（字节 -> 字符串（ASCII），去除尾部 0x00）
    final trimmed = List<int>.from(modelBytes);
    while (trimmed.isNotEmpty && trimmed.last == 0x00) {
      trimmed.removeLast();
    }
    final model = String.fromCharCodes(trimmed);

    /// 固件版本号（u16 数值 -> "MAJOR.MINOR.REVISION" 字符串）
    final fw = formatVersionU16(fwBytes);

    /// 硬件版本（u16 数值 -> "MAJOR.MINOR.REVISION" 字符串）
    ///
    final hw = formatVersionU16(hwBytes);

    /// 序列号（每段 u32 最大可表示 10 位十进制，因为要把3个sn数字拼接，所以左补零后拼接，确保固定长度表示）
    const segmentWidth = 10;
    final sn =
        '${padDecimalLeft(sn1Bytes, width: segmentWidth)}${padDecimalLeft(sn2Bytes, width: segmentWidth)}${padDecimalLeft(sn3Bytes, width: segmentWidth)}';

    return DeviceConnectionRes(
      model: model,
      firmwareVersion: fw,
      hardwareVersion: hw,
      serialNumber: sn,
    );
  }

  @override
  String toString() {
    return 'DeviceConnectionRes(model="$model", fwBytes=$firmwareVersion, hw=$hardwareVersion, sn=$serialNumber)';
  }

 
}

/// 工厂函数
/// 目前三层协议和第二层的cmd都是解耦的，通过工厂组合在一起
