import 'package:byte_message/src/models/layer1/inter_chip_models.dart';

/// 通用解码返回类型
///
/// 功能描述：
/// - 为所有协议/工厂的解码流程提供统一的返回结构，包含“状态”与“业务载荷”。
/// - 当状态非成功（具体由调用方定义）时，payload 可为空以表示没有有效业务数据。
///
/// 类型参数：
/// - [T]：业务载荷类型（例如 DeviceConnectionResponse、ControlBusMessage 等）。
class DecodeResult<T> {
  /// 解码得到的状态值（由具体协议定义其意义与成功判断）
  final InterChipCmds status;

  /// 解码得到的业务载荷；在状态非成功时可为空
  final T? data;

  /// 构造函数
  ///
  /// 参数：
  /// - [status] 解码状态
  /// - [data] 业务载荷（可空）
  const DecodeResult({required this.status, this.data});
}
