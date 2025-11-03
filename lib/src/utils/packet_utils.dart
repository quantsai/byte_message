/// Inter-chip协议工具类
library;

import '../constants/packet_constants.dart';

/// 数据包处理工具类
class PacketUtils {
  // 防止实例化
  PacketUtils._();

  // ==================== 字节序转换工具 ====================

  /// 将两个u8字节组合成u16值（小端序）
  ///
  /// [low] 低位字节
  /// [high] 高位字节
  /// 返回组合后的u16值
  static int bytesToInt16(int low, int high) {
    if (!PacketConstants.isValidU8(low)) {
      throw ArgumentError('Low byte must be a valid u8 value (0-255)');
    }
    if (!PacketConstants.isValidU8(high)) {
      throw ArgumentError('High byte must be a valid u8 value (0-255)');
    }
    return (high << 8) | low;
  }

  /// 将u16值拆分成两个u8字节（小端序）
  ///
  /// [value] 要拆分的u16值
  /// 返回[低位字节, 高位字节]
  static List<int> int16ToBytes(int value) {
    if (!PacketConstants.isValidU16(value)) {
      throw ArgumentError('Value must be a valid u16 value (0-65535)');
    }
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  // ==================== 校验和计算工具 ====================

  /// 计算数据的XOR校验和
  ///
  /// [data] 要计算校验和的数据
  /// 返回XOR校验和结果
  static int calculateXorChecksum(List<int> data) {
    int checksum = 0;
    for (int byte in data) {
      if (!PacketConstants.isValidU8(byte)) {
        throw ArgumentError('All data bytes must be valid u8 values (0-255)');
      }
      checksum ^= byte;
    }
    return checksum;
  }

  /// 验证数据的XOR校验和
  ///
  /// [data] 原始数据（不包含校验和）
  /// [expectedChecksum] 期望的校验和值
  /// 返回true如果校验和匹配
  static bool verifyXorChecksum(List<int> data, int expectedChecksum) {
    if (!PacketConstants.isValidU8(expectedChecksum)) {
      throw ArgumentError('Expected checksum must be a valid u8 value (0-255)');
    }
    return calculateXorChecksum(data) == expectedChecksum;
  }

  // ==================== 数据验证工具 ====================

  /// 验证载荷长度是否有效
  ///
  /// [length] 载荷长度
  /// 返回true如果长度有效
  static bool isValidPayloadLength(int length) {
    return length >= 0 && length <= PacketConstants.MAX_PAYLOAD_LONG;
  }

  /// 检查是否为应答命令
  ///
  /// [cmd] 命令字节值
  /// 返回true如果是应答命令
  static bool isResponseCommand(int cmd) {
    // 简化实现：根据命令值判断是否为应答
    // 实际项目中可以根据具体协议定义进行判断
    return cmd == PacketConstants.RESPONSE_FORCE_SYNC ||
        cmd == PacketConstants.RESPONSE_TEST_COMMUNICATION ||
        cmd == PacketConstants.RESPONSE_OK ||
        cmd == PacketConstants.RESPONSE_ERROR ||
        cmd == PacketConstants.RESPONSE_INVALID;
  }

  /// 检查是否为命令协议
  ///
  /// [cmd] 命令字节值
  /// 返回true如果是命令协议
  static bool isCommandProtocol(int cmd) {
    return cmd == PacketConstants.CMD_CONTROL_BUS;
  }

  /// 检查是否为DFU协议
  ///
  /// [cmd] 命令字节值
  /// 返回true如果是DFU协议
  static bool isDfuProtocol(int cmd) {
    return cmd == PacketConstants.CMD_DFU;
  }

  /// 验证长度字段的一致性
  ///
  /// [len] 长度低位
  /// [lenH] 长度高位（可选）
  /// [actualPayloadLength] 实际负载长度（包含Cmd）
  /// 返回true如果长度一致
  static bool isValidLength(int len, int? lenH, int actualPayloadLength) {
    if (!PacketConstants.isValidU8(len)) return false;
    if (lenH != null && !PacketConstants.isValidU8(lenH)) return false;

    int declaredLength;
    if (lenH != null) {
      declaredLength = bytesToInt16(len, lenH);
    } else {
      declaredLength = len;
    }

    return declaredLength == actualPayloadLength;
  }

  /// 验证命令字段的有效性
  ///
  /// [cmd] 命令值
  /// 返回true如果命令有效
  static bool isValidCommand(int cmd) {
    return PacketConstants.isValidU8(cmd);
  }

  /// 验证负载数据的有效性
  ///
  /// [payload] 负载数据
  /// 返回true如果所有字节都是有效的u8值
  static bool isValidPayload(List<int> payload) {
    for (int byte in payload) {
      if (!PacketConstants.isValidU8(byte)) return false;
    }
    return true;
  }

  // ==================== 数据包分析工具 ====================

  /// 分析数据包的基本信息
  ///
  /// [data] 原始数据包字节
  /// 返回包含分析结果的Map
  static Map<String, dynamic> analyzePacket(List<int> data) {
    if (data.isEmpty) {
      return {'error': 'Empty packet data'};
    }

    Map<String, dynamic> analysis = {};

    try {
      // 分析Flag
      int flag = data[0];
      analysis['flag'] = '0x${flag.toRadixString(16).padLeft(2, '0')}';
      analysis['longFrame'] = PacketConstants.isLongFrameEnabled(flag);
      analysis['checksumEnabled'] = PacketConstants.isChecksumEnabled(flag);

      if (data.length < 2) {
        analysis['error'] = 'Packet too short, missing Len field';
        return analysis;
      }

      // 分析长度
      int len = data[1];
      analysis['len'] = len;

      bool longFrame = PacketConstants.isLongFrameEnabled(flag);
      int headerLength = PacketConstants.calculateMinPacketLength(
        longFrame: longFrame,
        checksumEnabled: PacketConstants.isChecksumEnabled(flag),
      );

      if (longFrame) {
        if (data.length < 3) {
          analysis['error'] = 'Long frame packet missing LenH field';
          return analysis;
        }
        int lenH = data[2];
        analysis['lenH'] = lenH;
        analysis['totalLength'] = bytesToInt16(len, lenH);
      } else {
        analysis['totalLength'] = len;
      }

      analysis['expectedPacketLength'] =
          headerLength +
          analysis['totalLength'] -
          1; // -1 because Cmd is included in totalLength
      analysis['actualPacketLength'] = data.length;
      analysis['lengthMatch'] =
          analysis['expectedPacketLength'] == analysis['actualPacketLength'];
    } catch (e) {
      analysis['error'] = 'Analysis failed: $e';
    }

    return analysis;
  }

  /// 格式化字节数组为十六进制字符串
  ///
  /// [data] 字节数组
  /// [separator] 分隔符，默认为空格
  /// 返回格式化的十六进制字符串
  static String formatBytes(List<int> data, [String separator = ' ']) {
    return data
        .map((byte) => '0x${byte.toRadixString(16).padLeft(2, '0')}')
        .join(separator);
  }

  /// 从十六进制字符串解析字节数组
  ///
  /// [hexString] 十六进制字符串，支持多种格式
  /// 返回解析后的字节数组
  static List<int> parseHexString(String hexString) {
    // 移除常见的分隔符和前缀
    String cleaned = hexString
        .replaceAll('0x', '') // 先移除0x前缀
        .replaceAll('0X', '') // 移除0X前缀
        .replaceAll(RegExp(r'[^0-9a-fA-F]'), '') // 移除其他非十六进制字符
        .toUpperCase();

    if (cleaned.isEmpty) {
      throw ArgumentError('Hex string cannot be empty after cleaning');
    }

    if (cleaned.length % 2 != 0) {
      throw ArgumentError('Hex string must have even number of characters');
    }

    List<int> bytes = [];
    for (int i = 0; i < cleaned.length; i += 2) {
      String byteStr = cleaned.substring(i, i + 2);
      try {
        int byte = int.parse(byteStr, radix: 16);
        bytes.add(byte);
      } catch (e) {
        throw ArgumentError('Invalid hex characters in string: $byteStr');
      }
    }

    return bytes;
  }

  // ==================== 调试工具 ====================

  /// 生成数据包的调试信息
  ///
  /// [data] 数据包字节
  /// 返回详细的调试信息字符串
  static String generateDebugInfo(List<int> data) {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('=== Packet Debug Info ===');
    buffer.writeln('Raw data: ${formatBytes(data)}');
    buffer.writeln('Length: ${data.length} bytes');

    Map<String, dynamic> analysis = analyzePacket(data);
    analysis.forEach((key, value) {
      buffer.writeln('$key: $value');
    });

    return buffer.toString();
  }
}
