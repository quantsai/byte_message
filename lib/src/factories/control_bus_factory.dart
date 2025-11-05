/// Control Bus 三层组合工厂
///
/// 作用：按“第二层协议分文件”的组织方式，提供将三层协议（Layer1/Layer2/Layer3）在一次调用中完成编码或解码的能力。
/// - 本文件聚合 Control Bus 相关的三层编解码流程（连接请求/连接应答）。
/// - 层次职责：
///   - Layer3：业务载荷（例如连接请求的协议版本、连接应答的模型/版本/序列号）
///   - Layer2：ControlBus 子命令（CbCmd）及其负载（CbPayload）
///   - Layer1：Inter-chip 包装帧（Flag/Len/LenH/Cmd/Payload/Checksum）
///
/// 使用说明：
/// - encodeConnectionReq：输入第三层请求模型，一次性输出可发送的一层完整字节流；
/// - decodeConnectionRes：输入一层原始字节流，一次性返回第三层应答模型。
library;

import '../models/layer1/inter_chip_models.dart';
import '../models/layer2/control_bus_models.dart';
import '../protocols/layer1/inter_chip_encoder.dart';
import '../protocols/layer1/inter_chip_decoder.dart';
import '../protocols/layer2/control_bus/control_bus_encoder.dart';
import '../protocols/layer3/control_bus/device_connection.dart';
import '../protocols/layer3/control_bus/battery_status.dart';
import '../models/decode_result.dart';

/// Control Bus 三层组合工厂
// 移除特定类型的解码结果类，改用通用 DecodeResult<S, T>

class ControlBusFactory {
  /// 编码：设备连接请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“设备连接请求”的协议版本编码为二层 ControlBusMessage（CbCmd=0x10），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [protocolVersion] 第三层协议版本（u8，默认 0x02）。
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  ///
  /// 异常：
  /// - RangeError/ArgumentError：当内层编码参数非法时抛出（来自各层编码器的校验）。
  List<int> encodeConnectionReq({
    int protocolVersion = 0x02,
    int? flag,
  }) {
    // 1) Layer3：在内部创建请求对象并编码第三层负载
    final request = DeviceConnectionReq(protocolVersion: protocolVersion);
    final l3 = request.encode();

    // 2) Layer2 封装：CbCmd=0x10（连接请求），CbPayload=第三层负载
    const int cbCmdConnectionRequest = 0x10;
    final l2Message =
        ControlBusMessage(cbCmd: cbCmdConnectionRequest, cbPayload: l3);
    final l2 = ControlBusEncoder().encode(l2Message); // [0x10, ...]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag, // 若为 null，编码器会自动生成合适的 Flag（含校验和使能）
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：设备连接应答（一次调用从一层原始字节流还原第三层模型）
  DecodeResult<DeviceConnectionRes> decodeConnectionRes(List<int> rawData) {
    try {
      // 1) Layer1 解码
      final l1 = InterChipDecoder().decode(rawData);
      if (l1 == null) {
        throw ArgumentError('Invalid inter-chip packet: decode failed');
      }

      if (l1.cmd != InterChipCmds.ackOk) {
        return DecodeResult<DeviceConnectionRes>(status: l1.cmd, data: null);
      }

      final l3 = l1.payload;

      // 第三层载荷长度必须为 28（型号12 + fw2 + hw2 + sn(4*3)）
      if (l3.length != (12 + 2 + 2 + 4 * 3)) {
        throw ArgumentError(
            'Invalid L3 connection response payload length: expected 28, got ${l3.length}');
      }

      // 4) Layer3 解码为业务模型
      final resp = DeviceConnectionRes.fromBytes(l3);
      return DecodeResult<DeviceConnectionRes>(status: l1.cmd, data: resp);
    } catch (e) {
      throw ArgumentError(e);
    }
  }

  /// 编码：电量与充电状态请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“电量/充电状态请求”的负载（空数组）编码为二层 ControlBusMessage（CbCmd=0x30），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeBatteryStatusReq({int? flag}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = BatteryStatusReq().encode(); // []

    // 2) Layer2 封装：CbCmd=0x30（电量/充电状态请求），CbPayload=第三层负载
    const int cbCmdBatteryStatusRequest = 0x30;
    final l2Message = ControlBusMessage(
      cbCmd: cbCmdBatteryStatusRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x30]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：电量与充电状态应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 2 时，返回解析后的 BatteryStatusRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<BatteryStatusRes> decodeBatteryStatusRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<BatteryStatusRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // 按设备约定：AckOK 的 payload 为第三层载荷

    // 电量/充电状态第三层载荷长度必须为 2（百分比 u8 + 状态 u8）
    if (l3.length != 2) {
      throw ArgumentError(
        'Invalid L3 battery status payload length: expected 2, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = BatteryStatusRes.fromBytes(l3);
    return DecodeResult<BatteryStatusRes>(status: l1.cmd, data: resp);
  }
}
