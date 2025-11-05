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
import '../protocols/layer3/control_bus/get_device_connection.dart';
import '../protocols/layer3/control_bus/get_battery_status.dart';
import '../protocols/layer3/control_bus/get_electrical_metrics.dart';
import '../protocols/layer3/control_bus/get_device_status.dart';
import '../protocols/layer3/control_bus/get_operating_mode.dart';
import '../protocols/layer3/control_bus/get_speed_gear.dart';
import '../protocols/layer3/control_bus/set_speed.dart';
import '../protocols/layer3/control_bus/set_pushrod_speed.dart';
import '../protocols/layer3/control_bus/set_operating_mode.dart';
import '../protocols/layer3/control_bus/set_speed_gear.dart';
import '../protocols/layer3/control_bus/set_joystick.dart';
import '../protocols/layer3/control_bus/set_fold_state.dart';
import '../models/decode_result.dart';
import '../models/layer2/control_bus_cmds.dart';

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
    final request = GetDeviceConnectionReq(protocolVersion: protocolVersion);
    final l3 = request.encode();

    // 2) Layer2 封装：CbCmd=0x10（连接请求），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.connectionRequest,
      cbPayload: l3,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x10, ...]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag, // 若为 null，编码器会自动生成合适的 Flag（含校验和使能）
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 编码：设置折叠/展开请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“设置折叠/展开请求”的负载（u8：0x00 折叠 / 0x01 展开）编码为二层 ControlBusMessage（CbCmd=0x82），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [state] 折叠/展开枚举（FoldState）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeSetFoldStateReq({
    required FoldState state,
    int? flag,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（u8 0/1）
    final l3Payload = SetFoldStateReq(state: state).encode(); // [state]

    // 2) Layer2 封装：CbCmd=0x82（设置折叠/展开），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.foldControlRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x82, state]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：设置折叠/展开应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 0 时，返回解析后的 SetFoldStateAck；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<SetFoldStateAck> decodeSetFoldStateAck(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<SetFoldStateAck>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 设置折叠/展开第三层载荷长度必须为 0（无第三层负载）
    if (l3.isNotEmpty) {
      throw ArgumentError(
        'Invalid L3 set fold state ack payload length: expected 0, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型（无载荷，仅 Ack）
    const resp = SetFoldStateAck();
    return DecodeResult<SetFoldStateAck>(status: l1.cmd, data: resp);
  }

  /// 解码：设备连接应答（一次调用从一层原始字节流还原第三层模型）
  DecodeResult<GetDeviceConnectionRes> decodeConnectionRes(List<int> rawData) {
    try {
      // 1) Layer1 解码
      final l1 = InterChipDecoder().decode(rawData);
      if (l1 == null) {
        throw ArgumentError('Invalid inter-chip packet: decode failed');
      }

      if (l1.cmd != InterChipCmds.ackOk) {
        return DecodeResult<GetDeviceConnectionRes>(status: l1.cmd, data: null);
      }

      final l3 = l1.payload;

      // 第三层载荷长度必须为 28（型号12 + fw2 + hw2 + sn(4*3)）
      if (l3.length != (12 + 2 + 2 + 4 * 3)) {
        throw ArgumentError(
            'Invalid L3 connection response payload length: expected 28, got ${l3.length}');
      }

      // 4) Layer3 解码为业务模型
      final resp = GetDeviceConnectionRes.fromBytes(l3);
      return DecodeResult<GetDeviceConnectionRes>(status: l1.cmd, data: resp);
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
    final l3Payload = GetBatteryStatusReq().encode(); // []

    // 2) Layer2 封装：CbCmd=0x30（电量/充电状态请求），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.batteryStatusRequest,
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
  DecodeResult<GetBatteryStatusRes> decodeBatteryStatusRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<GetBatteryStatusRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // 按设备约定：AckOK 的 payload 为第三层载荷

    // 电量/充电状态第三层载荷长度必须为 2（百分比 u8 + 状态 u8）
    if (l3.length != 2) {
      throw ArgumentError(
        'Invalid L3 battery status payload length: expected 2, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = GetBatteryStatusRes.fromBytes(l3);
    return DecodeResult<GetBatteryStatusRes>(status: l1.cmd, data: resp);
  }

  /// 编码：电压与电流请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“电压/电流请求”的负载（空数组）编码为二层 ControlBusMessage（CbCmd=0x36），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeElectricalMetricsReq({int? flag}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = GetElectricalMetricsReq().encode(); // []

    // 2) Layer2 封装：CbCmd=0x36（电压/电流请求），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.electricalMetricsRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x36]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 编码：机器状态请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“机器状态请求”的负载（空数组）编码为二层 ControlBusMessage（CbCmd=0x37），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeDeviceStatusReq({int? flag}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = GetDeviceStatusReq().encode(); // []

    // 2) Layer2 封装：CbCmd=0x37（机器状态请求），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.deviceStatusRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x37]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 编码：功能模式请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“功能模式请求”的负载（空数组）编码为二层 ControlBusMessage（CbCmd=0x3D），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeOperatingModeReq({int? flag}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = GetOperatingModeReq().encode(); // []

    // 2) Layer2 封装：CbCmd=0x3D（功能模式请求），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.operatingModeRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x3D]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 编码：设置操作模式请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“设置操作模式请求”的负载（u8 模式值）编码为二层 ControlBusMessage（CbCmd=0x4D），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [mode] 操作模式（OperatingMode 枚举）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeSetOperatingModeReq({
    required OperatingMode mode,
    int? flag,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（u8 模式值）
    final l3Payload = SetOperatingModeReq(mode: mode).encode(); // [mode]

    // 2) Layer2 封装：CbCmd=0x4D（设置操作模式），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.operatingModeControlRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x4D, mode]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 编码：设置速度请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“设置速度请求”的负载（线速度/角速度，均为 float32 BE）编码为二层 ControlBusMessage（CbCmd=0x41），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [linear] 线速度（m/s，float32）
  /// - [angular] 角速度（r/s，float32）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeSpeedControlReq({
    required double linear,
    required double angular,
    int? flag,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（float32 BE*2）
    final l3Payload = SetSpeedReq(
      linearVelocity: linear,
      angularVelocity: angular,
    ).encode(); // [lin(4), ang(4)]

    // 2) Layer2 封装：CbCmd=0x41（设置速度请求），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.speedControlRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x41, ...]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：机器状态应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 5 时，返回解析后的 DeviceStatusRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<GetDeviceStatusRes> decodeDeviceStatusRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<GetDeviceStatusRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 机器状态第三层载荷长度必须为 5（状态 u8 + 错误码 u32）
    if (l3.length != 5) {
      throw ArgumentError(
        'Invalid L3 device status payload length: expected 5, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = GetDeviceStatusRes.fromBytes(l3);
    return DecodeResult<GetDeviceStatusRes>(status: l1.cmd, data: resp);
  }

  /// 编码：速度档位请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“速度档位请求”的负载（空数组）编码为二层 ControlBusMessage（CbCmd=0x3E），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeSpeedGearReq({int? flag}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = GetSpeedGearReq().encode(); // []

    // 2) Layer2 封装：CbCmd=0x3E（速度档位请求），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.speedGearRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x3E]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：速度档位应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 1 时，返回解析后的 SpeedGearRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<GetSpeedGearRes> decodeSpeedGearRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<GetSpeedGearRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 速度档位第三层载荷长度必须为 1（u8 档位）
    if (l3.length != 1) {
      throw ArgumentError(
        'Invalid L3 speed gear payload length: expected 1, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = GetSpeedGearRes.fromBytes(l3);
    return DecodeResult<GetSpeedGearRes>(status: l1.cmd, data: resp);
  }

  /// 解码：功能模式应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 1 时，返回解析后的 OperatingModeRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<GetOperatingModeRes> decodeOperatingModeRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<GetOperatingModeRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 功能模式第三层载荷长度必须为 1（u8 模式）
    if (l3.length != 1) {
      throw ArgumentError(
        'Invalid L3 operating mode payload length: expected 1, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = GetOperatingModeRes.fromBytes(l3);
    return DecodeResult<GetOperatingModeRes>(status: l1.cmd, data: resp);
  }

  /// 解码：设置速度应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 0 时，返回解析后的 SpeedControlAck；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<SetSpeedAck> decodeSpeedControlAck(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<SetSpeedAck>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 设置速度第三层载荷长度必须为 0（无第三层负载）
    if (l3.isNotEmpty) {
      throw ArgumentError(
        'Invalid L3 speed control ack payload length: expected 0, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型（无载荷，仅 Ack）
    final resp = SetSpeedAck.fromBytes(l3);
    return DecodeResult<SetSpeedAck>(status: l1.cmd, data: resp);
  }

  /// 编码：设置速度档位请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“设置速度档位请求”的负载（u8 档位值）编码为二层 ControlBusMessage（CbCmd=0x4E），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [gear] 速度档位（SpeedGear 枚举）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeSetSpeedGearReq({
    required SpeedGear gear,
    int? flag,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（u8 档位值）
    final l3Payload = SetSpeedGearReq(gear: gear).encode(); // [gear]

    // 2) Layer2 封装：CbCmd=0x4E（设置速度档位），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.speedGearControlRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x4E, gear]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：设置速度档位应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 0 时，返回解析后的 SetSpeedGearAck；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<SetSpeedGearAck> decodeSetSpeedGearAck(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<SetSpeedGearAck>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 设置速度档位第三层载荷长度必须为 0（无第三层负载）
    if (l3.isNotEmpty) {
      throw ArgumentError(
        'Invalid L3 set speed gear ack payload length: expected 0, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型（无载荷，仅 Ack）
    final resp = const SetSpeedGearAck();
    return DecodeResult<SetSpeedGearAck>(status: l1.cmd, data: resp);
  }

  /// 编码：设置推杆速度请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“设置推杆速度请求”的负载（四路 s32 BE：A/B/C/D）编码为二层 ControlBusMessage（CbCmd=0x42），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [a] 推杆 A 速度（s32）
  /// - [b] 推杆 B 速度（s32）
  /// - [c] 推杆 C 速度（s32）
  /// - [d] 推杆 D 速度（s32）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeSetPushRodSpeedReq({
    required double a,
    required double b,
    required double c,
    required double d,
    int? flag,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（s32 BE * 4）
    final l3Payload = SetPushRodSpeedReq(
      speedA: a,
      speedB: b,
      speedC: c,
      speedD: d,
    ).encode(); // [A(4), B(4), C(4), D(4)]

    // 2) Layer2 封装：CbCmd=0x42（设置推杆速度），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.pushRodControlRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x42, ...]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 编码：设置摇杆请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“设置摇杆请求”的负载（三轴 s16 BE：X/Y/Z，业务范围 -100..100）编码为二层 ControlBusMessage（CbCmd=0x81），
  ///   再包装为一层 InterChipPacket（Cmd=0xF8 普通指令），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [x] X 轴偏量（百分比，范围 -100..100，s16 BE 编码）
  /// - [y] Y 轴偏量（百分比，范围 -100..100，s16 BE 编码）
  /// - [z] Z 轴偏量（百分比，范围 -100..100，s16 BE 编码）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeSetJoystickReq({
    required int x,
    required int y,
    int z = 0,
    int? flag,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（s16 BE * 3）
    final l3Payload =
        SetJoystickReq(x: x, y: y, z: z).encode(); // [X(2), Y(2), Z(2)]

    // 2) Layer2 封装：CbCmd=0x81（设置摇杆），CbPayload=第三层负载
    final l2Message = ControlBusMessage(
      cbCmd: CbCmd.joystickControlRequest,
      cbPayload: l3Payload,
    );
    final l2 = ControlBusEncoder().encode(l2Message); // [0x81, ...]

    // 3) Layer1 包装：Cmd=0xF8（普通指令），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.normal,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：设置摇杆应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 0 时，返回解析后的 SetJoystickAck；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<SetJoystickAck> decodeSetJoystickAck(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<SetJoystickAck>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 设置摇杆第三层载荷长度必须为 0（无第三层负载）
    if (l3.isNotEmpty) {
      throw ArgumentError(
        'Invalid L3 set joystick ack payload length: expected 0, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型（无载荷，仅 Ack）
    const resp = SetJoystickAck();
    return DecodeResult<SetJoystickAck>(status: l1.cmd, data: resp);
  }

  /// 解码：设置推杆速度应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 0 时，返回解析后的 SetPushRodSpeedAck；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<SetPushRodSpeedAck> decodeSetPushRodSpeedAck(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<SetPushRodSpeedAck>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 设置推杆速度第三层载荷长度必须为 0（无第三层负载）
    if (l3.isNotEmpty) {
      throw ArgumentError(
        'Invalid L3 set pushrod speed ack payload length: expected 0, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型（无载荷，仅 Ack）
    final resp = SetPushRodSpeedAck.fromBytes(l3);
    return DecodeResult<SetPushRodSpeedAck>(status: l1.cmd, data: resp);
  }

  /// 解码：设置操作模式应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 0 时，返回解析后的 SetOperatingModeAck；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<SetOperatingModeAck> decodeSetOperatingModeAck(
      List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<SetOperatingModeAck>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 设置操作模式第三层载荷长度必须为 0（无第三层负载）
    if (l3.isNotEmpty) {
      throw ArgumentError(
        'Invalid L3 set operating mode ack payload length: expected 0, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型（无载荷，仅 Ack）
    final resp = const SetOperatingModeAck();
    return DecodeResult<SetOperatingModeAck>(status: l1.cmd, data: resp);
  }

  /// 解码：电压与电流应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK 且第三层载荷长度为 8 时，返回解析后的 ElectricalMetricsRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<GetElectricalMetricsRes> decodeElectricalMetricsRes(
      List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<GetElectricalMetricsRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 电压/电流第三层载荷长度必须为 8（电压 s32 + 电流 s32）
    if (l3.length != 8) {
      throw ArgumentError(
        'Invalid L3 voltage/current payload length: expected 8, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = GetElectricalMetricsRes.fromBytes(l3);
    return DecodeResult<GetElectricalMetricsRes>(status: l1.cmd, data: resp);
  }
}
