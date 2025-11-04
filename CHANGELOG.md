## 1.0.0 (2025-11-04)

- 初始发布：Inter-chip 协议编码/解码库

## 1.1.0 (2025-11-04)

- models: PacketFlags 提供 encode()/decode() 能力，明确位定义（LongFrame、ChecksumEnable）
- decoder: 移除配置依赖，简化解码逻辑，统一失败返回 null，并始终严格验证校验和
- example: 新增 PacketFlags 使用示例，演示 encode 与 decode 的反向操作
- style: 清理多余空行与注释代码
