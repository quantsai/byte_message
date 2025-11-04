/// 通用校验工具函数集合
///
/// 提供数值范围校验工具，便于在各层协议实现中复用并保持一致的异常信息。
library byte_message.utils.validation;

/// 校验给定值是否为无符号 8 位整数（u8，范围 0..255）。
///
/// 参数：
/// - [value] 待校验的数值。
/// - [name] 字段名称（用于异常消息），默认 'value'。
///
/// 返回：
/// - 无（void）。当校验通过时直接返回。
///
/// 异常：
/// - [RangeError] 当 [value] 超出 u8 范围（0..255）时抛出，异常中包含 [name] 以便定位。
void ensureU8(int value, {String name = 'value'}) {
  if (value < 0 || value > 0xFF) {
    throw RangeError.value(value, name, 'Must be u8');
  }
}
