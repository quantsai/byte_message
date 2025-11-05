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

/// 从 4 字节的大端序（BE）数组读取一个无符号 32 位整数（U32）。
///
/// 功能：
/// - 将 [bytes] 的 4 个字节当作 BE 序（高字节在前），组合为一个十进制整型数值（0..4294967295）。
///
/// 参数：
/// - [bytes] 至少包含 4 个字节，按 BE 顺序排列：[b0, b1, b2, b3]。
///
/// 返回：
/// - [int] 无符号 32 位整数值（U32）。
int readU32BE(List<int> bytes) {
  if (bytes.length < 4) {
    throw ArgumentError('readU32BE requires 4 bytes, got ${bytes.length}');
  }
  final b0 = bytes[0] & 0xFF;
  final b1 = bytes[1] & 0xFF;
  final b2 = bytes[2] & 0xFF;
  final b3 = bytes[3] & 0xFF;
  return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
}

/// 从 2 字节的大端序（BE）数组读取一个无符号 16 位整数（U16）。
///
/// 功能：
/// - 将 [bytes] 的 2 个字节当作 BE 序（高字节在前），组合为一个十进制整型数值（0..65535）。
///
/// 参数：
/// - [bytes] 至少包含 2 个字节，按 BE 顺序排列：[b0, b1]。
///
/// 返回：
/// - [int] 无符号 16 位整数值（U16）。
int readU16BE(List<int> bytes) {
  if (bytes.length < 2) {
    throw ArgumentError('readU16BE requires 2 bytes, got ${bytes.length}');
  }
  final b0 = bytes[0] & 0xFF;
  final b1 = bytes[1] & 0xFF;
  return (b0 << 8) | b1;
}

// 将 u32 值转换成一个数字（0..4294967295）
int u32FromBytes(List<int> bytes) {
  return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
}

/// 把浮点数转换成 4 字节的大端序（BE）数组。
///
/// 参数：
/// - [value] 浮点数（double）。
/// 返回：
/// - [List<int>] 4 字节的大端序数组（[b0, b1, b2, b3]）。
List<int> packF32BE(double value) {
  final b0 = (value.toInt() >> 24) & 0xFF;
  final b1 = (value.toInt() >> 16) & 0xFF;
  final b2 = (value.toInt() >> 8) & 0xFF;
  final b3 = value.toInt() & 0xFF;
  return [b0, b1, b2, b3];
}

/// 把浮点数转换成 2 字节的大端序（BE）数组。
///
/// 参数：
/// - [value] 浮点数（double）。
/// 返回：
/// - [List<int>] 2 字节的大端序数组（[b0, b1]）。
List<int> packF16BE(double value) {
  final b0 = (value.toInt() >> 8) & 0xFF;
  final b1 = value.toInt() & 0xFF;
  return [b0, b1];
}

// 将 u32 值转换成一个固定宽度的字符串（默认 10 位），左侧补齐 '0'。
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
