/// 设置摇杆（Set Joystick）第三层协议
///
/// - CbCmd: 0x81 （摇杆控制）
/// - 请求负载：X/Y/Z 三轴偏量，均为 s16（签名 16 位，大端序），业务范围 [-100, 100]
/// - 应答负载：无（Ack-only）
library byte_message.l3.control_bus.set_joystick;

import 'dart:typed_data';

/// 设置摇杆请求（SetJoystickReq）
class SetJoystickReq {
  /// X 轴偏量（百分比，范围 -100..100），正为前，负为后
  final int x;

  /// Y 轴偏量（百分比，范围 -100..100），正为左，负为右
  final int y;

  /// Z 轴偏量（百分比，范围 -100..100），预留
  final int z;

  /// 构造函数
  ///
  /// 参数：
  /// - [x] X 轴偏量，int，范围 -100..100
  /// - [y] Y 轴偏量，int，范围 -100..100
  /// - [z] Z 轴偏量，int，范围 -100..100（预留）
  const SetJoystickReq({
    required this.x,
    required this.y,
    required this.z,
  });

  /// 编码为字节数组（s16 BE * 3）
  ///
  /// 返回：长度为 6 的字节数组，顺序为 X(2) + Y(2) + Z(2)
  /// 异常：当任一轴偏量超出业务范围 -100..100 时抛出 RangeError
  List<int> encode() {
    _ensurePercent(x, name: 'x');
    _ensurePercent(y, name: 'y');
    _ensurePercent(z, name: 'z');

    final bytes = <int>[];
    bytes.addAll(_packS16BE(x));
    bytes.addAll(_packS16BE(y));
    bytes.addAll(_packS16BE(z));
    return bytes;
  }

  /// 校验百分比范围（-100..100）
  void _ensurePercent(int value, {required String name}) {
    if (value < -100 || value > 100) {
      throw RangeError.value(value, name, 'Joystick percent must be -100..100');
    }
  }

  /// 将 Dart int 以有符号 16 位（s16）大端序编码为 2 字节
  ///
  /// 参数：
  /// - [value] 要编码的整数（范围：-32768..32767，调用前已做业务范围校验）
  /// 返回：长度为 2 的字节数组（BE）
  List<int> _packS16BE(int value) {
    final b = ByteData(2);
    b.setInt16(0, value, Endian.big);
    return [b.getUint8(0), b.getUint8(1)];
  }
}

/// 设置摇杆应答（SetJoystickAck）
///
/// 此应答无负载，工厂在解码时仅校验 AckOK 与负载为空
class SetJoystickAck {
  /// 构造函数（空负载应答）
  const SetJoystickAck();
}