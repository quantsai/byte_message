/// DFU 第三层协议：获取设备信息（Get Device Info）
///
/// 文档参考：byte_message.md#L199-213
/// - 请求：DfuCmd=0x01，DfuVersion=0x01，第三层请求负载为空（无数据）。
/// - 应答：按文档定义的字段序列（均为大端序 BE）：
///   DfuPkgVersion u8,
///   BootloaderVersion u16,
///   BootloaderPageCnt u16,
///   DeviceType u16,
///   PageNum u32,
///   PageSize u32,
///   RomVersion u32,
///   VenderInfo u32,
///   HardwareVersion u16,
///   DfuDeviceFlag u32,
///   DfuDevicePowerVolt u32。
///
/// 设计约束：
/// - 与前两层解耦，仅处理第三层内容字节（不包含 Cmd / DfuCmd / DfuVersion 等二/一层字段）。
library byte_message.l3.dfu.get_device_info;

/// 获取设备信息请求（第三层）
///
/// 第三层请求负载为空，DFU 二层会携带 DfuCmd=0x01 与 DfuVersion=0x01。
class GetDeviceInfoReq {
  /// 生成第三层请求负载（空内容）
  ///
  /// 返回：
  /// - List<int> 空数组（[]），表示第三层无负载内容。
  List<int> encode() => const [];
}

/// 获取设备信息应答（第三层）
///
/// 负责解析“获取设备信息”请求的第三层应答负载，字段均为 BE：
/// - DfuPkgVersion u8
/// - BootloaderVersion u16
/// - BootloaderPageCnt u16
/// - DeviceType u16
/// - PageNum u32
/// - PageSize u32
/// - RomVersion u32
/// - VenderInfo u32
/// - HardwareVersion u16
/// - DfuDeviceFlag u32
/// - DfuDevicePowerVolt u32
class GetDeviceInfoRes {
  /// DFU 包版本（字符串版本号：MAJOR.MINOR.REVISION，由 u8 派生）
  final List<int> dfuPkgVersion;

  /// Bootloader 版本（字符串版本号：MAJOR.MINOR.REVISION，由 u16 派生）
  final List<int> bootloaderVersion;

  /// Bootloader 页数（u16）
  final List<int> bootloaderPageCnt;

  /// 设备类型（u16）
  final List<int> deviceType;

  /// 页编号（u32）
  final List<int> pageNum;

  /// 页大小（u32）
  final List<int> pageSize;

  /// ROM 版本（字符串版本号：MAJOR.MINOR.REVISION，依据 u32 的高三字节派生）
  final String romVersion;

  /// 厂商信息（u32）
  final List<int> venderInfo;

  /// 硬件版本（字符串版本号：MAJOR.MINOR.REVISION，由 u16 派生）
  final List<int> hardwareVersion;

  /// DFU 设备标志（u32）
  final List<int> dfuDeviceFlag;

  /// DFU 设备电压（u32）
  final List<int> dfuDevicePowerVolt;

  /// 构造函数
  ///
  /// 参数：
  /// - 对应文档的各字段，均按大端序解析后的整型值
  GetDeviceInfoRes({
    required this.dfuPkgVersion,
    required this.bootloaderVersion,
    required this.bootloaderPageCnt,
    required this.deviceType,
    required this.pageNum,
    required this.pageSize,
    required this.romVersion,
    required this.venderInfo,
    required this.hardwareVersion,
    required this.dfuDeviceFlag,
    required this.dfuDevicePowerVolt,
  });

  /// 从第三层应答字节解析模型
  ///
  /// 参数：
  /// - [bytes] 第三层应答负载字节（不含一层/二层字段），总长度必须为 33 字节。
  ///
  /// 返回：
  /// - [GetDeviceInfoRes] 解析后的应答数据模型
  ///
  /// 异常：
  /// - [ArgumentError] 当长度不为 33 或字节不足时抛出
  static GetDeviceInfoRes fromBytes(List<int> bytes) {
    const expectedLength = 33;
    if (bytes.length != expectedLength) {
      throw ArgumentError(
        'Invalid DFU device info payload length: expected $expectedLength, got ${bytes.length}',
      );
    }

    // 先按字段边界切片字节，再逐一转换
    final dfuPkgVersionBytes = bytes.sublist(0, 1);
    final bootloaderVersionBytes = bytes.sublist(1, 3);
    final bootloaderPageCntBytes = bytes.sublist(3, 5);
    final deviceTypeBytes = bytes.sublist(5, 7);
    final pageNumBytes = bytes.sublist(7, 11);
    final pageSizeBytes = bytes.sublist(11, 15);
    final romVersionBytes = bytes.sublist(15, 19);
    final venderInfoBytes = bytes.sublist(19, 23);
    final hardwareVersionBytes = bytes.sublist(23, 25);
    final dfuDeviceFlagBytes = bytes.sublist(25, 29);
    final dfuDevicePowerVoltBytes = bytes.sublist(29, 33);

    // 转换为最终内容（仅修改 ROM 版本解析规则）：
    // BE 四字节 [b0,b1,b2,b3]，左边第一位 b0 不用，版本号为 b1.b2.b3，且第三段两位数左补零
    final romMajor = romVersionBytes[1] & 0xFF;
    final romMinor = romVersionBytes[2] & 0xFF;
    final romRevision = romVersionBytes[3] & 0xFF;
    final romVersion =
        '$romMajor.$romMinor.${romRevision.toString().padLeft(2, '0')}';

    return GetDeviceInfoRes(
      dfuPkgVersion: dfuPkgVersionBytes,
      bootloaderVersion: bootloaderVersionBytes,
      bootloaderPageCnt: bootloaderPageCntBytes,
      deviceType: deviceTypeBytes,
      pageNum: pageNumBytes,
      pageSize: pageSizeBytes,
      romVersion: romVersion,
      venderInfo: venderInfoBytes,
      hardwareVersion: hardwareVersionBytes,
      dfuDeviceFlag: dfuDeviceFlagBytes,
      dfuDevicePowerVolt: dfuDevicePowerVoltBytes,
    );
  }

  @override
  String toString() {
    return 'GetDeviceInfoRes(dfuPkgVersion="$dfuPkgVersion", bootloaderVersion="$bootloaderVersion", bootloaderPageCnt=$bootloaderPageCnt, deviceType=$deviceType, pageNum=$pageNum, pageSize=$pageSize, romVersion="$romVersion", venderInfo=$venderInfo, hardwareVersion="$hardwareVersion", dfuDeviceFlag=$dfuDeviceFlag, dfuDevicePowerVolt=$dfuDevicePowerVolt)';
  }
}
