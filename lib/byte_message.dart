/// Inter-chip协议编码解码库
///
/// 提供完整的inter-chip通讯协议编码和解码功能
/// 支持标准的数据包格式：|Flag|Len|LenH|Cmd|Payload|Checksum|
library;

// 导出核心数据模型
export 'src/models/layer1/inter_chip_models.dart';
export 'src/models/layer2/control_bus_models.dart';
export 'src/models/layer2/dfu_models.dart';

// 导出协议常量
export 'src/constants/packet_constants.dart';

// 导出工具类
export 'src/utils/packet_utils.dart';

// 导出抽象接口（第一层 Layer1）
export 'src/interfaces/layer1/layer1_packet_encoder.dart';
export 'src/interfaces/layer1/layer1_packet_decoder.dart';
// 导出抽象接口（第二层 Layer2）
export 'src/interfaces/layer2/layer2_payload_encoder.dart';
export 'src/interfaces/layer2/layer2_payload_decoder.dart';

// 导出编码器实现
export 'src/protocols/layer1/inter_chip_encoder.dart';
export 'src/protocols/layer2/control_bus/control_bus_encoder.dart';
export 'src/protocols/layer2/dfu/dfu_encoder.dart';

// 导出解码器实现
export 'src/protocols/layer1/inter_chip_decoder.dart';
export 'src/protocols/layer2/control_bus/control_bus_decoder.dart';
export 'src/protocols/layer2/dfu/dfu_decoder.dart';
// 导出第三层协议（Control Bus）
export 'src/protocols/layer3/control_bus/device_connection.dart';
export 'src/protocols/layer3/control_bus/battery_status.dart';
export 'src/protocols/layer3/control_bus/electrical_metrics.dart';
export 'src/protocols/layer3/control_bus/device_status.dart';
export 'src/protocols/layer3/control_bus/operating_mode.dart';
export 'src/protocols/layer3/control_bus/speed_gear.dart';
export 'src/protocols/layer3/control_bus/set_pushrod_speed.dart';
export 'src/protocols/layer3/control_bus/set_speed.dart';
export 'src/protocols/layer3/control_bus/set_operating_mode.dart';
export 'src/protocols/layer3/control_bus/set_speed_gear.dart';
export 'src/protocols/layer3/control_bus/set_joystick.dart';
export 'src/protocols/layer3/control_bus/set_fold_state.dart';

// 导出工厂类（按第二层协议分文件组织）
export 'src/factories/control_bus_factory.dart';
export 'src/models/decode_result.dart';
