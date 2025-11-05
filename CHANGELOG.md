## 1.0.0 (2025-11-04)

- 初始发布：Inter-chip 协议编码/解码库

## 1.1.0 (2025-11-04)

- models: InterChipFlags 提供 encode()/decode() 能力，明确位定义（LongFrame、ChecksumEnable）
- decoder: 移除配置依赖，简化解码逻辑，统一失败返回 null，并始终严格验证校验和
- example: 新增 InterChipFlags 使用示例，演示 encode 与 decode 的反向操作
- style: 清理多余空行与注释代码

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

## Unreleased

### 接口泛型化：Layer1 抽象不再写死具体类型

- Layer1PacketEncoder 现支持泛型类型参数 `P`（包模型类型）与 `F`（标志位类型），避免在共用抽象接口中写死 `InterChipPacket` 与 `InterChipFlags`
- 目的：提升可复用性，允许不同协议在保持统一方法语义的同时，使用自己的包与标志位类型
- 适配：`InterChipEncoder` 已更新为实现 `Layer1PacketEncoder<InterChipPacket, InterChipFlags>`，其余实现类可按需指定类型参数
- 兼容：既有调用方无需更改使用方式（方法签名保持不变，仅类型参数由实现类提供）
- 验证：`dart analyze`（No issues found）与 `dart test -r compact`（All tests passed）均通过

### 异常结构调整：EncoderException 独立文件

- 将通用编码器异常 `EncoderException` 从 `layer1_packet_encoder.dart` 移至独立文件 `src/interfaces/encoder_exception.dart`
- 目的：解耦接口与异常实现，保持接口文件仅承载抽象定义
- 适配：`InterChipEncoder` 与测试文件显式导入新的异常文件路径
- 验证：`dart analyze`（No issues found）与 `dart test -r compact`（All tests passed）均通过

### 接口泛型化：Layer1PacketDecoder 与 DecodeResult 泛型化

- Layer1PacketDecoder 现支持泛型类型参数 `P`（包模型类型）与 `F`（标志位类型），并将 `DecodeResult<P, F>` 泛型化，彻底移除接口中的 `InterChipPacket` 等具体类型。
- 目的：提升共用抽象的通用性，避免解码抽象与具体协议实现耦合。
- 适配：`InterChipDecoder` 已更新为实现 `Layer1PacketDecoder<InterChipPacket, InterChipFlags>`，并使用 `DecodeResult<InterChipPacket, InterChipFlags>`。
- 验证：`dart analyze`（No issues found）与 `dart test -r compact`（All tests passed）均通过。

### 异常结构调整：DecoderException 独立文件

- 将通用解码器异常 `DecoderException` 从 `layer1_packet_decoder.dart` 移至独立文件 `src/interfaces/decoder_exception.dart`
- 目的：解耦接口与异常实现，保持接口文件仅承载抽象定义。
- 适配：`InterChipDecoder` 显式导入新的异常文件路径（如需抛出内部一致性错误）。
- 验证：`dart analyze`（No issues found）与 `dart test -r compact`（All tests passed）均通过。

### 清理：移除未使用的 InterChipDecoder.tryDecodePartial

- 删除 `src/protocols/layer1/inter_chip_decoder.dart` 中未被引用的方法 `tryDecodePartial(List<int>)`
- 说明：相关“部分数据解析”需求由 `calculateExpectedLength` 与 `decodeMultiple` 实现覆盖，因此该方法冗余。
- 验证：`dart analyze`（No issues found）与 `dart test -r compact`（All tests passed）均通过。

### 更名：抽象接口统一为 Layer1 命名

- 文件：`src/interfaces/inter_chip_packet_encoder.dart` -> `src/interfaces/layer1_packet_encoder.dart`
- 文件：`src/interfaces/inter_chip_packet_decoder.dart` -> `src/interfaces/layer1_packet_decoder.dart`
- 类名：`InterChipPacketEncoder` -> `Layer1PacketEncoder`
- 类名：`InterChipPacketDecoder` -> `Layer1PacketDecoder`
- 兼容：提供 `typedef PacketEncoder = Layer1PacketEncoder;`、`typedef PacketDecoder = Layer1PacketDecoder;`，以及 `typedef InterChipPacketEncoder = Layer1PacketEncoder;`、`typedef InterChipPacketDecoder = Layer1PacketDecoder;`，旧名称继续可用
- 导出：`lib/byte_message.dart` 改为导出 `layer1_packet_encoder.dart` 与 `layer1_packet_decoder.dart`
- 实现类：`InterChipEncoder` / `InterChipDecoder` 现实现 `Layer1*` 接口

### 设计调整：二层接口抽象与一层解耦

- 新增二层抽象接口：`Layer2PayloadEncoder<T>`、`Layer2PayloadDecoder<T>`（仅处理二层字节序列，避免与一层语义耦合）
- ControlBusEncoder/ControlBusDecoder、DfuEncoder/DfuDecoder 现实现上述接口
- ControlBusDecoder.decode 与 DfuDecoder.decode 现在仅接收一层 payload（List<int>），不再耦合 InterChipPacket
- 模型工厂方法命名调整：`ControlBusMessage.fromBytes(List<int>)`、`DfuMessage.fromBytes(List<int>)`（避免“payload”与一层语义耦合，基于参数类型命名）
- 示例更新：将 decodedPacket.payload 传入二层解码器
- 移除 `ControlBusMessage.fromPacket(InterChipPacket)` 与 `ControlBusMessage.toPacket()`，进一步消除二层与一层耦合，统一由上层 Packet/Encoder 负责组包与拆包
- 说明：由上层根据 InterChip Cmd 选择对应的二层解码器，本解码器仅负责负载解析

迁移建议：

- 如直接引用接口文件路径（src），请将 `inter_chip_packet_*` 改为 `layer1_packet_*`
- 如仅使用实现类或通过 `PacketEncoder/PacketDecoder` 类型别名，无需更改

### 模型合并：统一 InterChip 一层命令定义

- 合并文件：`src/models/inter_chip_models.dart` 与 `src/models/packet_command.dart`
  - 现在 `InterChipCmds` 枚举定义直接位于 `inter_chip_models.dart`
  - 为兼容旧导入路径，`packet_command.dart` 保留为对 `InterChipCmds` 的 re-export
- 清理：移除代码与测试中的冗余 `packet_command.dart` 引用（由分析器提示 unnecessary_import）
- 验证：`dart analyze`（No issues found）与 `dart test -r compact`（All tests passed）均通过

### 兼容入口移除：删除 `packet_command.dart`

- 删除兼容性 re-export 文件：`src/models/packet_command.dart`
- 公共导出清理：移除 `lib/byte_message.dart` 中对该文件的 export
- 引用更新：测试与源码统一从 `src/models/inter_chip_models.dart` 导入 `InterChipCmds`
- 验证：`dart analyze`（No issues found）与 `dart test -r compact`（All tests passed）

### 清理：移除接口层 EncoderException，统一使用标准异常

- 删除 `src/interfaces/layer1/layer1_packet_encoder.dart` 中的 `EncoderException` 自定义异常类型，接口层仅保留抽象方法定义。
- 实现层 `InterChipEncoder` 统一改为抛出标准异常：
  - `RangeError`：字段取值超出范围（如 flag、payload 长度）
  - `ArgumentError`：参数语义错误（如长度不匹配、非法命令）
  - `StateError`：不合法的状态组合（如 len 为 null 而 lenH 非 null）
- 测试更新：将 `throwsA(isA<EncoderException>())` 分别改为 `throwsA(isA<RangeError>())` 与 `throwsA(isA<ArgumentError>())`，保持语义一致。
- 说明：接口层不再约束自定义异常，推荐实现层使用 Dart 标准异常以提升通用性与可读性。
- 验证：`dart analyze`（No issues found）与 `dart test -r expanded`（All tests passed）均通过。

### 新增：第三层协议（Control Bus）- 请求连接协议

- 新增文件：`src/protocols/layer3/control_bus/connection_protocol.dart`
- 能力：
  - 请求编码：实例方法 `DeviceConnectionReq.encode()` 生成第三层请求负载；类属性 `protocolVersion`（默认 `0x02`，可配置）
  - 应答解码：`DeviceConnectionRes.fromBytes(List[int])` 解析第三层应答负载（默认使用大端序解析 u16/u32）；数据模型更新：
    - 型号改为字符串 `model`（由 u8[12] ASCII 转换并去除尾部 0x00）
    - 固件/硬件版本字段改为字符串（格式 `MAJOR.MINOR.REVISION`，由 u16 按 `MAJOR<<8 | MINOR<<4 | REVISION` 规则解析）
    - 序列号改为字符串（3 个 u32（大端）数字的十进制拼接）
- 设计：第三层与前两层完全解耦，仅处理第三层内容字节；上层负责将第三层内容放入第二层/第一层载荷
- 导出：`lib/byte_message.dart` 新增对该文件的 export
- 测试：新增 `test/layer3_control_bus_connection_test.dart`，覆盖请求编码与应答解码的正常与异常场景
  - 更新：测试已改为实例化 `DeviceConnectionReq()` 并调用 `encode()`；非法版本在构造时抛出 `RangeError`
  - 更新：响应模型断言改为 `resp.model` 字符串（不再检查原始 `modelBytes` 与 `modelString`）；版本断言为 `'0.0.0'`，序列号断言为 `'000'`
- 验证：`dart analyze`（No issues found）与 `dart test -r expanded`（All tests passed）
