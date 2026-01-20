## 1.7.0 (2026-01-20)

- feat: 新增 Layer3 业务层协议完整实现
  - ControlBus: 支持设置/获取速度、推杆控制、电量、设备信息等全套指令
  - DFU: 支持固件升级全流程（GetDeviceInfo, Start/FinishUpgrade, WriteChunk/Bulk）
- feat: 新增 `ControlBusFactory` 和 `DfuFactory`，提供开箱即用的业务层编解码能力
- refactor: Layer1 接口泛型化
  - `Layer1PacketEncoder/Decoder` 支持泛型参数，解耦具体协议实现
  - 异常类 `EncoderException`/`DecoderException` 独立拆分
- test: 新增大量集成测试与单元测试，核心工厂类测试覆盖率 >94%

## 1.2.0 (2025-11-04)

- interfaces: 重命名第一层抽象接口文件与类名，明确语义
  - 文件 `src/interfaces/packet_encoder.dart` -> `src/interfaces/inter_chip_packet_encoder.dart`
  - 文件 `src/interfaces/packet_decoder.dart` -> `src/interfaces/inter_chip_packet_decoder.dart`
  - 类名 `PacketEncoder` -> `InterChipPacketEncoder`
  - 类名 `PacketDecoder` -> `InterChipPacketDecoder`
  - 兼容：提供 `typedef PacketEncoder = InterChipPacketEncoder;` 与 `typedef PacketDecoder = InterChipPacketDecoder;`，旧代码无需修改即可继续工作
- exports: 更新 `lib/byte_message.dart` 对应导出路径为新的接口文件
- layer2 encoders: 明确二层编码器（ControlBusEncoder、DfuEncoder）仅输出二层负载字节，不包含一层 inter-chip 字段
- example: 更新示例，先编码二层负载，再由一层 `InterChipPacket` 组帧序列化
- qa: 通过 `dart analyze`（0 issues）与 `dart test -r compact`（All tests passed）

## 1.1.0 (2025-11-04)

- models: InterChipFlags 提供 encode()/decode() 能力，明确位定义（LongFrame、ChecksumEnable）
- decoder: 移除配置依赖，简化解码逻辑，统一失败返回 null，并始终严格验证校验和
- example: 新增 InterChipFlags 使用示例，演示 encode 与 decode 的反向操作
- style: 清理多余空行与注释代码

## 1.0.0 (2025-11-04)

- 初始发布：Inter-chip 协议编码/解码库
