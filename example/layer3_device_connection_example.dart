/// 示例：第三层设备连接请求/应答的编码与解码
///
/// 本示例演示：
/// 1) 生成第三层“设备连接请求”的负载字节（与第一层/第二层解耦）
/// 2) 构造一个模拟的第三层应答负载（28 字节），并使用 DeviceConnectionResponse 解码
/// 3) 按 control.md 中的固件/硬件版本规则（MAJOR << 8 | MINOR << 4 | REVISION）拆解版本号
/// 4) 将型号字节转换为 ASCII 字符串、序列号三段连接为字符串
import 'package:byte_message/byte_message.dart';
import 'package:byte_message/src/utils/byte_packing.dart';

void main() {
  // 1) 生成第三层“设备连接请求”的负载字节（默认协议版本 0x02）
  final request = DeviceConnectionRequest();
  final requestPayload = request.encode();
  print('Layer3 Request Payload: $requestPayload'); // [0x02]

  // 2) 构造一个模拟的第三层“设备连接应答”的负载（28 字节）
  // 字段布局（BE，大端）：
  // model[12] | fw(u16, BE) | hw(u16, BE) | sn1(u32, BE) | sn2(u32, BE) | sn3(u32, BE)

  // 2.1 型号（ASCII，12 字节）
  final modelString = 'TT01DEVICE12'; // 恰好 12 字符
  final modelBytes = modelString.codeUnits; // ASCII 字节

  // 2.2 固件版本与硬件版本（按 control.md 规则）
  final fwVal = composeVersion(major: 1, minor: 3, revision: 0); // 1.3.0
  final hwVal = composeVersion(major: 2, minor: 1, revision: 4); // 2.1.4
  final fwBytes = packU16BE(fwVal);
  final hwBytes = packU16BE(hwVal);

  // 2.3 序列号三段（u32，BE），字符串为每段 10 位十进制左补零后拼接
  final sn1 = 0x01;
  final sn2 = 0x01;
  final sn3 = 0x02;
  final snBytes = [
    ...packU32BE(sn1),
    ...packU32BE(sn2),
    ...packU32BE(sn3),
  ];

  // 拼接 28 字节的第三层应答负载
  final responsePayload = <int>[
    ...modelBytes,
    ...fwBytes,
    ...hwBytes,
    ...snBytes,
  ];
  print(
      'Layer3 Response Payload (len=${responsePayload.length}): $responsePayload');

  // 3) 解码第三层应答
  final resp = DeviceConnectionResponse.fromBytes(responsePayload);
  print('mo: ${resp.model}');
  print('fw: ${resp.firmwareVersion}');
  print('hw: ${resp.hardwareVersion}');
  print('se: ${resp.serialNumber}');
}

// 组合/打包函数已提取为公共工具，详见：package:byte_message/src/utils/byte_packing.dart
