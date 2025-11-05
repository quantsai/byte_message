/// Inter-chip协议常量定义
library;

/// 数据包协议常量
class PacketConstants {
  // 防止实例化
  PacketConstants._();

  // ==================== Flag 字段常量 ====================

  /// 标准Flag值：长帧关闭，校验和关闭 (0x00)
  static const int FLAG_ = 0x00;

  /// 标准Flag值：长帧关闭，校验和启用 (0x10)
  static const int FLAG_CHECKSUM = 0x10;

  /// LongFrame位掩码（第6位）
  static const int FLAG_LONG = 0x40;

  /// 标准Flag值：长帧启用，校验和启用 (0x50)
  static const int FLAG_LONG_CHECKSUM = 0x50;

  /// ChecksumEnable位掩码（第4位）
  static const int FLAG_MASK_CHECKSUM_ENABLE = 0x10;

  // ==================== 长度限制常量 ====================

  /// 短帧模式下的最大负载长度（255字节）
  static const int MAX_PAYLOAD_SHORT = 255;

  /// 长帧模式下的最大负载长度（65535字节）
  static const int MAX_PAYLOAD_LONG = 65535;

  /// 标准帧的最大载荷长度（不包含Cmd字段）
  static const int maxStandardFramePayload = 254; // 255 - 1(Cmd)

  /// 长帧的最大载荷长度（包含Cmd字段）
  static const int maxLongFramePayload = 65535;

  /// u8字段的最大值
  static const int MAX_U8_VALUE = 255;

  /// u16字段的最大值
  static const int MAX_U16_VALUE = 65535;

  // ==================== 数据包结构常量 ====================

  /// 基础数据包头部长度（Flag + Len + Cmd）
  static const int BASE_HEADER_LENGTH = 3;

  /// 长帧模式下的额外头部长度（LenH字段）
  static const int LONG_FRAME_EXTRA_LENGTH = 1;

  /// 校验和字段长度
  static const int CHECKSUM_LENGTH = 1;

  /// 最小数据包长度（Flag + Len + Cmd + Checksum）
  static const int MIN_PACKET_LENGTH = 4;

  // ==================== 预留命令常量 ====================

  /// 强制同步命令
  static const int CMD_FORCE_SYNC = 0x00;

  /// 测试通讯命令
  static const int CMD_TEST_COMMUNICATION = 0x01;

  /// 预留命令范围起始
  static const int CMD_RESERVED_START = 0x00;

  /// 预留命令范围结束
  static const int CMD_RESERVED_END = 0x0F;

  // ==================== 应答命令常量 ====================

  // ==================== 错误码常量 ====================

  /// 请求包的校验和不匹配
  static const int ERROR_CHECKSUM_MISMATCH = 0x40;

  /// 请求包的长度超过缓冲区承受范围
  static const int ERROR_LENGTH_OVERFLOW = 0x20;

  /// 没有同接收方完成同步
  static const int ERROR_NOT_SYNCHRONIZED = 0x10;

  /// 请求包中的Cmd不被接收方支持
  static const int ERROR_UNSUPPORTED_CMD = 0x8000;

  /// 请求包在执行中遇到格式类错误
  static const int ERROR_FORMAT_ERROR = 0x8001;

  /// 请求包在执行中遇到操作类错误
  static const int ERROR_OPERATION_ERROR = 0x8002;

  // ==================== 扩展协议常量 ====================

  /// 协议类型：命令协议
  static const int protocolTypeCommand = 0x01;

  /// 协议类型：DFU协议
  static const int protocolTypeDfu = 0x02;

  /// 协议类型：预留
  static const int protocolTypeReserved = 0x00;

  /// 控制指令协议命令字段
  static const int CMD_CONTROL_BUS = 0xF8;

  /// DFU协议命令字段
  static const int CMD_DFU = 0x20;

  // ==================== 工具方法 ====================

  /// 检查是否为有效的u8值
  ///
  /// [value] 要检查的值
  /// 返回true如果值在0-255范围内
  static bool isValidU8(int value) {
    return value >= 0 && value <= MAX_U8_VALUE;
  }

  /// 检查是否为有效的u16值
  ///
  /// [value] 要检查的值
  /// 返回true如果值在0-65535范围内
  static bool isValidU16(int value) {
    return value >= 0 && value <= MAX_U16_VALUE;
  }

  /// 检查是否为预留命令
  ///
  /// [cmd] 命令值
  /// 返回true如果是预留命令
  static bool isReservedCommand(int cmd) {
    return cmd >= CMD_RESERVED_START && cmd <= CMD_RESERVED_END;
  }

  /// 检查Flag是否启用长帧模式
  ///
  /// [flag] Flag字节值
  /// 返回true如果启用长帧模式
  static bool isLongFrameEnabled(int flag) {
    return (flag & FLAG_LONG) != 0;
  }

  /// 检查Flag是否启用校验和
  ///
  /// [flag] Flag字节值
  /// 返回true如果启用校验和
  static bool isChecksumEnabled(int flag) {
    return (flag & FLAG_MASK_CHECKSUM_ENABLE) != 0;
  }

  /// 根据负载长度判断是否需要长帧模式
  ///
  /// [payloadLength] 负载长度（包含Cmd字段）
  /// 返回true如果需要长帧模式
  static bool requiresLongFrame(int payloadLength) {
    return payloadLength > MAX_PAYLOAD_SHORT;
  }

  /// 计算数据包的最小长度
  ///
  /// [longFrame] 是否为长帧模式
  /// [checksumEnabled] 是否启用校验和
  /// 返回最小数据包长度
  static int calculateMinPacketLength({
    required bool longFrame,
    required bool checksumEnabled,
  }) {
    int length = BASE_HEADER_LENGTH; // Flag + Len + Cmd
    if (longFrame) length += LONG_FRAME_EXTRA_LENGTH; // LenH
    if (checksumEnabled) length += CHECKSUM_LENGTH; // Checksum
    return length;
  }
}
