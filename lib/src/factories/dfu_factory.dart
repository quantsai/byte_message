/// DFU 三层组合工厂
///
/// 作用：按“第二层协议分文件”的组织方式，提供将三层协议（Layer1/Layer2/Layer3）在一次调用中完成编码或解码的能力。
/// - 本文件聚合 DFU 相关的三层编解码流程（获取设备信息）。
/// - 层次职责：
///   - Layer3：业务载荷（例如获取设备信息请求的第三层负载为空，应答字段为 u8/u16/u32）
///   - Layer2：DFU 子命令（DfuCmd）及其负载（DfuPayload）
///   - Layer1：Inter-chip 包装帧（Flag/Len/LenH/Cmd/Payload/Checksum）
library;

import '../models/layer1/inter_chip_models.dart';
import '../models/layer2/dfu_models.dart';
import '../models/layer2/dfu_cmd.dart';
import '../models/decode_result.dart';
import '../protocols/layer1/inter_chip_encoder.dart';
import '../protocols/layer1/inter_chip_decoder.dart';
import '../protocols/layer2/dfu/dfu_encoder.dart';
import '../protocols/layer3/dfu/get_device_info.dart';
import '../protocols/layer3/dfu/start_upgrade.dart';
import '../protocols/layer3/dfu/finish_upgrade.dart';
import '../protocols/layer3/dfu/write_upgrade_chunk.dart';
import '../protocols/layer3/dfu/dfu_blob.dart';
import '../protocols/layer3/dfu/write_upgrade_bulk.dart';

/// DFU 三层组合工厂
class DfuFactory {
  /// 编码：获取设备信息请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“获取设备信息请求”的负载（空数组）编码为二层 DfuMessage（DfuCmd=0x01, DfuVersion=0x01），
  ///   再包装为一层 InterChipPacket（Cmd=0x20 DFU），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeGetDeviceInfoReq({int? flag, int dfuPkgVersion = 0x01}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = GetDeviceInfoReq().encode(); // []

    // 2) Layer2 封装：DfuCmd=0x01（获取设备信息），DfuVersion=dfuPkgVersion，DfuPayload=第三层负载
    final l2Message = DfuMessage(
      dfuCmd: DfuCmd.getDeviceInfo,
      dfuVersion: dfuPkgVersion,
      dfuPayload: l3Payload,
    );
    final l2 = DfuEncoder().encode(l2Message); // [0x01, 0x01]

    // 3) Layer1 包装：Cmd=0x20（DFU），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.dfu,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：获取设备信息应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK（0x02）且第三层载荷长度为 33 时，返回解析后的 GetDeviceInfoRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<GetDeviceInfoRes> decodeGetDeviceInfoRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<GetDeviceInfoRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 获取设备信息第三层载荷长度必须为 33（见文档）
    if (l3.length < 33) {
      throw ArgumentError(
        'Invalid L3 DFU device info payload length: expected 33, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = GetDeviceInfoRes.fromBytes(l3);
    return DecodeResult<GetDeviceInfoRes>(status: l1.cmd, data: resp);
  }

  /// 编码：开始升级请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“开始升级请求”的负载（空数组）编码为二层 DfuMessage（DfuCmd=0x02, DfuVersion=0x01），
  ///   再包装为一层 InterChipPacket（Cmd=0x20 DFU），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeStartUpgradeReq({int? flag, int dfuPkgVersion = 0x01}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = StartUpgradeReq().encode(); // []

    // 2) Layer2 封装：DfuCmd=0x02（开始升级），DfuVersion=0x01，DfuPayload=第三层负载
    final l2Message = DfuMessage(
      dfuCmd: DfuCmd.startUpgrade,
      dfuVersion: dfuPkgVersion,
      dfuPayload: l3Payload,
    );
    final l2 = DfuEncoder().encode(l2Message);

    // 3) Layer1 包装：Cmd=0x20（DFU），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.dfu,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：开始升级应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK（0x02）且第三层载荷长度为 2 时，返回解析后的 StartUpgradeRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<StartUpgradeRes> decodeStartUpgradeRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<StartUpgradeRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 开始升级第三层载荷长度必须为 2（见文档：u8 + u8）
    if (l3.length < 2) {
      throw ArgumentError(
        'Invalid L3 DFU start upgrade payload length: expected 2, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = StartUpgradeRes.fromBytes(l3);
    return DecodeResult<StartUpgradeRes>(status: l1.cmd, data: resp);
  }

  /// 编码：完成升级请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“完成升级请求”的负载（空数组）编码为二层 DfuMessage（DfuCmd=0x03, DfuVersion=0x01），
  ///   再包装为一层 InterChipPacket（Cmd=0x20 DFU），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeFinishUpgradeReq({int? flag, int dfuPkgVersion = 0x01}) {
    // 1) Layer3：创建请求对象并编码第三层负载（空数组）
    final l3Payload = FinishUpgradeReq().encode(); // []

    // 2) Layer2 封装：DfuCmd=0x03（完成升级），DfuVersion=0x01，DfuPayload=第三层负载
    final l2Message = DfuMessage(
      dfuCmd: DfuCmd.finishUpgrade,
      dfuVersion: dfuPkgVersion,
      dfuPayload: l3Payload,
    );
    final l2 = DfuEncoder().encode(l2Message);

    // 3) Layer1 包装：Cmd=0x20（DFU），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.dfu,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：完成升级应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK（0x02）且第三层载荷长度为 2 时，返回解析后的 FinishUpgradeRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<FinishUpgradeRes> decodeFinishUpgradeRes(List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<FinishUpgradeRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 完成升级第三层载荷长度必须为 2（见文档：u8 + u8）
    if (l3.length < 2) {
      throw ArgumentError(
        'Invalid L3 DFU finish upgrade payload length: expected 2, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = FinishUpgradeRes.fromBytes(l3);
    return DecodeResult<FinishUpgradeRes>(status: l1.cmd, data: resp);
  }

  /// 编码：写升级包请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“写升级包请求”的负载（DfuBlob）编码为二层 DfuMessage（DfuCmd=0x05, DfuVersion=0x01），
  ///   再包装为一层 InterChipPacket（Cmd=0x20 DFU），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [blob] 必填：升级数据片段 DfuBlob（包含 pageId/blobId/blobStart/blobData）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  /// - [dfuPkgVersion] 可选：DFU 协议版本（u8），默认 0x01。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeWriteUpgradeChunkReq({
    required DfuBlob blob,
    int? flag,
    int dfuPkgVersion = 0x01,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（DfuBlob）
    final l3Payload = WriteUpgradeChunkReq(blob: blob).encode();

    // 2) Layer2 封装：DfuCmd=0x05（写升级包），DfuVersion=dfuPkgVersion，DfuPayload=第三层负载
    final l2Message = DfuMessage(
      dfuCmd: DfuCmd.writeUpgradeChunk,
      dfuVersion: dfuPkgVersion,
      dfuPayload: l3Payload,
    );
    final l2 = DfuEncoder().encode(l2Message);

    // 3) Layer1 包装：Cmd=0x20（DFU），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.dfu,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：写升级包应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK（0x02）且第三层载荷长度为 2 时，返回解析后的 WriteUpgradeChunkRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<WriteUpgradeChunkRes> decodeWriteUpgradeChunkRes(
      List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<WriteUpgradeChunkRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 写升级包第三层载荷长度必须为 2（见文档：u8 + u8）
    if (l3.length < 2) {
      throw ArgumentError(
        'Invalid L3 DFU write upgrade chunk payload length: expected 2, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = WriteUpgradeChunkRes.fromBytes(l3);
    return DecodeResult<WriteUpgradeChunkRes>(status: l1.cmd, data: resp);
  }

  /// 编码：批量写升级包请求（一次调用产出最终一层字节流）
  ///
  /// 功能描述：
  /// - 将第三层“批量写升级包请求”的负载（DfuBlobList）编码为二层 DfuMessage（DfuCmd=0x07, DfuVersion=0x01），
  ///   再包装为一层 InterChipPacket（Cmd=0x20 DFU），最终输出完整字节序列。
  ///
  /// 参数说明：
  /// - [blobList] 必填：升级数据片段列表 DfuBlobList（包含 BlobCnt 和 blobs）
  /// - [flag] 可选：指定一层 Flag（u8）。若为 null，则编码器根据负载自动选择短帧/长帧并默认启用校验和。
  /// - [dfuPkgVersion] 可选：DFU 协议版本（u8），默认 0x01。
  ///
  /// 返回值：
  /// - List<int>：完整的一层字节流，可直接发送。
  List<int> encodeWriteUpgradeBulkReq({
    required DfuBlobList blobList,
    int? flag,
    int dfuPkgVersion = 0x01,
  }) {
    // 1) Layer3：创建请求对象并编码第三层负载（DfuBlobList）
    final l3Payload = WriteUpgradeBulkReq(blobList: blobList).encode();

    // 2) Layer2 封装：DfuCmd=0x07（批量写升级包），DfuVersion=dfuPkgVersion，DfuPayload=第三层负载
    final l2Message = DfuMessage(
      dfuCmd: DfuCmd.writeUpgradeBulk,
      dfuVersion: dfuPkgVersion,
      dfuPayload: l3Payload,
    );
    final l2 = DfuEncoder().encode(l2Message);

    // 3) Layer1 包装：Cmd=0x20（DFU），Payload=二层负载
    final packet = InterChipPacket(
      flag: flag,
      cmd: InterChipCmds.dfu,
      payload: l2,
    );

    return InterChipEncoder().encode(packet);
  }

  /// 解码：批量写升级包应答（一次调用从一层原始字节流还原第三层模型）
  ///
  /// 返回：
  /// - 当一层 Cmd 为 AckOK（0x02）且第三层载荷长度为 2 时，返回解析后的 WriteUpgradeBulkRes；
  /// - 否则返回状态并置 data 为 null。
  DecodeResult<WriteUpgradeBulkRes> decodeWriteUpgradeBulkRes(
      List<int> rawData) {
    // 1) Layer1 解码
    final l1 = InterChipDecoder().decode(rawData);
    if (l1 == null) {
      throw ArgumentError('Invalid inter-chip packet: decode failed');
    }

    if (l1.cmd != InterChipCmds.ackOk) {
      return DecodeResult<WriteUpgradeBulkRes>(status: l1.cmd, data: null);
    }

    final l3 = l1.payload; // AckOK 的 payload 为第三层载荷

    // 批量写升级包第三层载荷长度必须为 2（见文档：u8 + u8）
    if (l3.length < 2) {
      throw ArgumentError(
        'Invalid L3 DFU write upgrade bulk payload length: expected 2, got ${l3.length}',
      );
    }

    // 2) Layer3 解码为业务模型
    final resp = WriteUpgradeBulkRes.fromBytes(l3);
    return DecodeResult<WriteUpgradeBulkRes>(status: l1.cmd, data: resp);
  }
}
