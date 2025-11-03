/// Inter-chip协议编码解码库
///
/// 提供完整的inter-chip通讯协议编码和解码功能
/// 支持标准的数据包格式：|Flag|Len|LenH|Cmd|Payload|Checksum|
library;

// 导出核心数据模型
export 'src/models/packet_models.dart';
export 'src/models/packet_command.dart';

// 导出协议常量
export 'src/constants/packet_constants.dart';

// 导出工具类
export 'src/utils/packet_utils.dart';

// 导出抽象接口
export 'src/interfaces/packet_encoder.dart';
export 'src/interfaces/packet_decoder.dart';

// 导出编码器实现
export 'src/encoders/inter_chip_encoder.dart';

// 导出解码器实现
export 'src/decoders/inter_chip_decoder.dart';
