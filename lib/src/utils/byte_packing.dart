/// 字节打包与版本组合的通用工具函数
///
/// 提供 u16/u32 的小端序打包与固件/硬件版本号（MAJOR.MINOR.REVISION）组合，
/// 便于在协议实现与示例中复用，保持一致的行为与注释。
library byte_message.utils.byte_packing;

/// 组合固件/硬件版本号为 u16 值，符合 control.md：
/// MAJOR << 8 | MINOR << 4 | REVISION。
///
/// 参数：
/// - [major] 主版本 0..255
/// - [minor] 次版本 0..15
/// - [revision] 修订版本 0..15
/// 返回：
/// - [int] 组合后的 u16 数值（0..65535），可按具体协议约定以大小端序存储或传输。
int composeVersion(
    {required int major, required int minor, required int revision}) {
  return ((major & 0xFF) << 8) | ((minor & 0xF) << 4) | (revision & 0xF);
}

/// 将 16 位版本号数值转换为字符串 "MAJOR.MINOR.REVISION"。
///
/// 说明：
/// - 按 control.md 约定，u16 版本号的 bit 布局为：
///   MAJOR << 8 | MINOR << 4 | REVISION。
/// - 本函数仅做数值到字符串的格式化，与字节序无关（字节序只影响如何将字节还原为该 u16 数值）。
///
/// 参数：
/// - [value] 组合后的 u16 数值（0..65535）。
///
/// 返回：
/// - [String] 字符串形式的版本号，如 "1.2.3"。
String formatVersionU16(int value) {
  final major = (value >> 8) & 0xFF;
  final minor = (value >> 4) & 0x0F;
  final revision = value & 0x0F;
  return '$major.$minor.$revision';
}

/// 将 u16 值按小端序打包为 2 字节。
///
/// 参数：
/// - [value] 0..65535 的无符号数。
/// 返回：
/// - [List<int>] [b0, b1]，其中 b0 为低字节，b1 为高字节。
List<int> packU16LE(int value) {
  final b0 = value & 0xFF;
  final b1 = (value >> 8) & 0xFF;
  return [b0, b1];
}

/// 将 u32 值按小端序打包为 4 字节。
///
/// 参数：
/// - [value] 0..4294967295 的无符号数。
/// 返回：
/// - [List<int>] [b0, b1, b2, b3]，其中 b0 为最低字节，b3 为最高字节。
List<int> packU32LE(int value) {
  final b0 = value & 0xFF;
  final b1 = (value >> 8) & 0xFF;
  final b2 = (value >> 16) & 0xFF;
  final b3 = (value >> 24) & 0xFF;
  return [b0, b1, b2, b3];
}

/// 将 u16 值按大端序打包为 2 字节。
///
/// 参数：
/// - [value] 0..65535 的无符号数。
/// 返回：
/// - [List<int>] [b0, b1]，其中 b0 为高字节，b1 为低字节。
List<int> packU16BE(int value) {
  final b0 = (value >> 8) & 0xFF;
  final b1 = value & 0xFF;
  return [b0, b1];
}

/// 将 u32 值按大端序打包为 4 字节。
///
/// 参数：
/// - [value] 0..4294967295 的无符号数。
/// 返回：
/// - [List<int>] [b0, b1, b2, b3]，其中 b0 为最高字节，b3 为最低字节。
List<int> packU32BE(int value) {
  final b0 = (value >> 24) & 0xFF;
  final b1 = (value >> 16) & 0xFF;
  final b2 = (value >> 8) & 0xFF;
  final b3 = value & 0xFF;
  return [b0, b1, b2, b3];
}

/// 将十进制数字转换为固定宽度的字符串并在左侧补齐。
///
/// 用途：
/// - 格式化序列号段（如 u32 段）为固定宽度（默认 10 位）字符串，
///   以便进行稳定的字符串拼接与展示。
///
/// 参数：
/// - [value] 需要格式化的十进制数值（通常为非负整数，如 u32 值）。
/// - [width] 目标宽度（默认 10）。
/// - [padChar] 补齐字符（默认 '0'）。
///
/// 返回：
/// - [String] 左侧补齐至指定宽度的十进制字符串。
String padDecimalLeft(int value, {int width = 10, String padChar = '0'}) {
  return value.toString().padLeft(width, padChar);
}
