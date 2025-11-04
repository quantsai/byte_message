import '../interfaces/packet_encoder.dart';
import '../models/packet_models.dart';
import '../constants/packet_constants.dart';
import '../utils/packet_utils.dart';

/// Inter-chip协议编码器实现
///
/// 负责将InterChipPacket对象编码为二进制数据
/// 支持标准帧和长帧格式
class InterChipEncoder implements PacketEncoder {
  /// 是否自动设置标志位
  /// 当为true时，编码器会根据负载长度自动选择合适的标志位
  /// 当为false时，使用数据包中指定的标志位
  // final bool autoSetFlag;

  /// 构造函数
  const InterChipEncoder();

  @override
  List<int> encode(InterChipPacket packet) {
    // 验证数据包（始终进行基本验证）
    validatePacket(packet);

    // 自动生成标志位
    int flags =
        packet.flag == null ? generateFlags(packet).encode() : packet.flag!;

    // 计算总负载长度（包含Cmd字段）
    final totalPayloadLength = packet.totalPayloadLength;

    // 创建结果列表
    List<int> result = [];

    // 添加Flag
    result.add(flags);

    // 添加长度字段
    if (PacketFlags.fromFlag(flags).isLongFrame) {
      // 长帧模式：使用2字节长度
      final lengthBytes = PacketUtils.int16ToBytes(totalPayloadLength);
      result.addAll(lengthBytes);
    } else {
      // 标准帧模式：使用1字节长度
      result.add(totalPayloadLength);
    }

    // 添加命令字段
    result.add(packet.cmd.value);

    // 添加负载数据
    if (packet.payload.isNotEmpty) {
      result.addAll(packet.payload);
    }

    // 计算并添加校验和
    if (PacketFlags.fromFlag(flags).checksumEnable) {
      // 使用数据包的计算属性获取校验和
      final checksum = packet.checksum != null
          ? packet.checksum!
          : calculateChecksum(result);
      result.add(checksum);
    }
    return result;
  }

  String encodeToHex(InterChipPacket packet, {String separator = ' '}) {
    final bytes = encode(packet);
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(separator);
  }

  @override
  int calculateChecksum(List<int> data) {
    return PacketUtils.calculateXorChecksum(data);
  }

  @override
  void validatePacket(InterChipPacket packet) {
    // 验证flag - 当flag为null时跳过验证，当flag不为null时验证isValidU8
    if (packet.flag != null && !PacketConstants.isValidU8(packet.flag!)) {
      throw EncoderException('Invalid flag: ${packet.flag}');
    }

    // 验证命令字段
    if (!PacketUtils.isValidCommand(packet.cmd.value)) {
      throw EncoderException('Invalid command: ${packet.cmd}');
    }

    // 验证负载长度
    if (!PacketUtils.isValidPayloadLength(packet.payload.length)) {
      throw EncoderException(
        'Invalid payload length: ${packet.payload.length}',
      );
    }

    // 验证长度
    // 如果len!=null && lenH==null , 短帧的值等于cmd+payload的长度，则true
    // 如果len!=null && lenH!=null , 长帧的值等于cmd+payload的长度，则true
    // 如果len==null && lenH==null，则true
    // 否则则false
    final actualLength = packet.payload.length + 1; // cmd + payload

    if (packet.len != null && packet.lenH == null) {
      // 短帧模式：len应该等于实际长度
      if (packet.len != actualLength) {
        throw EncoderException(
          'Short frame length mismatch: expected $actualLength, got ${packet.len}',
        );
      }
    } else if (packet.len != null && packet.lenH != null) {
      // 长帧模式：计算 len(低位) + (lenH(高位) << 8) 应该等于实际长度
      final providedLength = (packet.len! << 8) + (packet.lenH!);
      if (providedLength != actualLength) {
        throw EncoderException(
          'Long frame length mismatch: expected $actualLength, got $providedLength',
        );
      }
    } else if (packet.len == null && packet.lenH == null) {
      // 都为null，允许通过（将自动计算）
    } else {
      // len为null但lenH不为null，这是无效的组合
      throw EncoderException(
        'Invalid length combination: len is null but lenH is not null',
      );
    }

    // 验证checksum
    // checksum==null，真
    // 当 checksum !=null 时：
    //  1. 若flag==null 则false
    //  2. 若flag!=null时
    //      2.1. flag中checksum==false，则false
    //      2.2. 若flag中checksum==true，
    //          2.2.1. 若f
    // 当flag==null && (flag中checksum)
  }

  @override
  bool requiresLongFrame(InterChipPacket packet) {
    return packet.totalPayloadLength > PacketConstants.maxStandardFramePayload;
  }

  /// 生成数据包标志位
  ///
  /// 根据文档要求，Flag只包含：
  /// - LongFrame (第6位): 是否为长帧
  /// - ChecksumEnable (第4位): 是否启用校验和
  /// - 其他位为预留位
  @override
  PacketFlags generateFlags(InterChipPacket packet) {
    final isLongFrame = requiresLongFrame(packet);
    // 默认启用校验和
    const checksumEnable = true;

    return PacketFlags(
      isLongFrame: isLongFrame,
      checksumEnable: checksumEnable,
    );
  }
}
