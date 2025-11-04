import '../../interfaces/layer1/layer1_packet_decoder.dart';
import '../../models/layer1/inter_chip_models.dart';
import '../../constants/packet_constants.dart';
import '../../utils/packet_utils.dart';
import 'inter_chip_encoder.dart';

/// Inter-chip协议解码器实现
///
/// 负责将二进制数据解码为InterChipPacket对象
/// 支持标准帧和长帧格式的解码
class InterChipDecoder
    implements Layer1PacketDecoder<InterChipPacket> {
  /// 构造函数（已移除配置依赖，采用固定的解码行为）
  const InterChipDecoder();

  @override
  InterChipPacket? decode(List<int> data) {
    try {
      // 基本格式验证
      if (!isValidPacketFormat(data)) {
        return null;
      }

      final flags = parseFlags(data[0]);

      // 解析长度字段
      int lengthFieldSize = flags.isLongFrame ? 2 : 1;
      int totalPayloadLength;

      if (flags.isLongFrame) {
        // 长帧模式：2字节长度
        if (data.length < 3) {
          return null;
        }
        totalPayloadLength = PacketUtils.bytesToInt16(data[1], data[2]);
      } else {
        // 标准帧模式：1字节长度
        if (data.length < 2) {
          return null;
        }
        totalPayloadLength = data[1];
      }

      // 计算期望的数据包总长度
      int expectedPacketLength = 1 + lengthFieldSize + totalPayloadLength;
      if (flags.checksumEnable) {
        expectedPacketLength += 1; // 校验和字段
      }

      // 验证数据长度
      if (data.length < expectedPacketLength) {
        return null;
      }

      // 解析命令字段
      int cmdIndex = 1 + lengthFieldSize;
      if (cmdIndex >= data.length) {
        return null;
      }

      final cmdValue = data[cmdIndex];
      InterChipCmds cmd;
      try {
        cmd = InterChipCmds.fromValue(cmdValue);
      } catch (e) {
        return null;
      }

      // 解析负载数据
      int payloadStartIndex = cmdIndex + 1;
      int payloadLength = totalPayloadLength - 1; // 减去cmd字段长度

      if (payloadLength < 0) {
        return null;
      }

      List<int> payload = [];
      if (payloadLength > 0) {
        int payloadEndIndex = payloadStartIndex + payloadLength;
        if (payloadEndIndex > data.length) {
          return null;
        }
        payload = data.sublist(payloadStartIndex, payloadEndIndex);
      }

      // 解析校验和（如果启用）
      int? receivedChecksum;
      if (flags.checksumEnable) {
        int checksumIndex = payloadStartIndex + payloadLength;
        if (checksumIndex >= data.length) {
          return null;
        }
        receivedChecksum = data[checksumIndex];

        // 验证校验和（在创建对象前进行验证）
        // 始终严格验证校验和
        List<int> dataForChecksum = data.sublist(0, checksumIndex);
        if (!verifyChecksum(dataForChecksum, receivedChecksum)) {
          return null;
        }
      }

      // 创建数据包对象（传递正确的len和lenH参数）
      final packet = InterChipPacket(
        flag: data[0],
        len: flags.isLongFrame ? data[1] : data[1],
        lenH: flags.isLongFrame ? data[2] : null,
        cmd: cmd,
        payload: payload,
        checksum: receivedChecksum,
      );

      return packet;
    } catch (e) {
      return null;
    }
  }

  @override
  bool verifyChecksum(List<int> data, int checksum) {
    if (data.isEmpty) {
      throw ArgumentError('Data cannot be empty for checksum verification');
    }

    final calculatedChecksum = PacketUtils.calculateXorChecksum(data);
    return calculatedChecksum == checksum;
  }

  InterChipFlags parseFlags(int flag) {
    if (flag < 0 || flag > 255) {
      throw ArgumentError('Flag value must be between 0 and 255, got: $flag');
    }

    return InterChipFlags.fromFlag(flag);
  }

  @override
  bool isValidPacketFormat(List<int> data) {
    if (data.isEmpty) {
      return false;
    }

    try {
      // 检查Flag字段是否有效
      final flags = parseFlags(data[0]);

      // 检查是否有足够的数据包含长度字段
      int lengthFieldSize = flags.isLongFrame ? 2 : 1;
      if (data.length < 1 + lengthFieldSize) {
        return false;
      }

      // 检查长度字段的值是否合理
      int totalPayloadLength;
      if (flags.isLongFrame) {
        totalPayloadLength = PacketUtils.bytesToInt16(data[1], data[2]);
      } else {
        totalPayloadLength = data[1];
      }

      // 负载长度必须至少为1（包含cmd字段）
      if (totalPayloadLength < 1) {
        return false;
      }

      // 计算期望的数据包长度
      int expectedLength = 1 + lengthFieldSize + totalPayloadLength;
      if (flags.checksumEnable) {
        expectedLength += 1;
      }

      // 检查数据长度是否匹配
      return data.length >= expectedLength;
    } catch (e) {
      return false;
    }
  }

  @override
  int? calculateExpectedLength(List<int> data) {
    if (data.isEmpty) {
      return null;
    }

    try {
      final flags = parseFlags(data[0]);
      int lengthFieldSize = flags.isLongFrame ? 2 : 1;

      // 检查是否有足够的数据读取长度字段
      if (data.length < 1 + lengthFieldSize) {
        return null;
      }

      int totalPayloadLength;
      if (flags.isLongFrame) {
        totalPayloadLength = PacketUtils.bytesToInt16(data[1], data[2]);
      } else {
        totalPayloadLength = data[1];
      }

      // 计算期望的总长度
      int expectedLength = 1 + lengthFieldSize + totalPayloadLength;
      if (flags.checksumEnable) {
        expectedLength += 1;
      }

      return expectedLength;
    } catch (e) {
      return null;
    }
  }

  List<InterChipPacket> decodeMultiple(List<int> data) {
    List<InterChipPacket> packets = [];
    int offset = 0;

    while (offset < data.length) {
      // 计算当前位置的期望包长度
      List<int> remainingData = data.sublist(offset);
      final expectedLength = calculateExpectedLength(remainingData);

      if (expectedLength == null || offset + expectedLength > data.length) {
        // 无法解析更多包
        break;
      }

      // 提取单个包的数据
      List<int> packetData = data.sublist(offset, offset + expectedLength);

      // 尝试解码
      final packet = decode(packetData);
      if (packet != null) {
        packets.add(packet);
        offset += expectedLength;
      } else {
        // 解码失败，跳过一个字节继续尝试
        offset++;
      }
    }

    return packets;
  }

  bool validatePacketIntegrity(InterChipPacket packet) {
    try {
      // 验证命令字段
      if (!InterChipCmds.isValidCommand(packet.cmd.value)) {
        return false;
      }

      // 验证负载长度
      if (packet.payload.length > PacketConstants.MAX_PAYLOAD_LONG) {
        return false;
      }

      // 验证标志位 - 只有当flags不为null时才验证
      final flags = packet.flags;
      if (flags != null) {
        if (flags.isLongFrame && packet.totalPayloadLength <= 255) {
          // 长帧模式但负载长度可以用单字节表示，这可能是不必要的
          // 但不算错误，只是不够优化
        }

        // 验证校验和（如果存在）
        if (flags.checksumEnable && packet.checksum != null) {
          // 重新编码数据包来验证校验和
          final encoder = InterChipEncoder();
          final encodedData = encoder.encode(packet);
          final decodedPacket = decode(encodedData);
          return decodedPacket != null;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
