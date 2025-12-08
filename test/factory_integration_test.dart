import 'package:test/test.dart';
import 'package:byte_message/src/factories/control_bus_factory.dart';
import 'package:byte_message/src/factories/dfu_factory.dart';
import 'package:byte_message/src/protocols/layer1/inter_chip_decoder.dart';
import 'package:byte_message/src/protocols/layer1/inter_chip_encoder.dart';
import 'package:byte_message/src/models/layer1/inter_chip_models.dart';
import 'package:byte_message/src/protocols/layer2/control_bus/control_bus_decoder.dart';
import 'package:byte_message/src/models/layer2/control_bus_cmd.dart';
import 'package:byte_message/src/protocols/layer2/dfu/dfu_decoder.dart';
import 'package:byte_message/src/models/layer2/dfu_cmd.dart';
import 'package:byte_message/src/protocols/layer3/control_bus/get_battery_status.dart';
import 'package:byte_message/src/protocols/layer3/control_bus/get_operating_mode.dart';
import 'package:byte_message/src/protocols/layer3/control_bus/get_device_status.dart';
import 'package:byte_message/src/protocols/layer3/control_bus/get_speed_gear.dart';
import 'package:byte_message/src/protocols/layer3/control_bus/get_device_language.dart';
import 'package:byte_message/src/protocols/layer3/control_bus/get_mute_status.dart';
import 'package:byte_message/src/protocols/layer3/control_bus/set_fold_state.dart';
import 'package:byte_message/src/protocols/layer3/dfu/write_upgrade_chunk.dart';

void main() {
  group('ControlBusFactory integration', () {
    /// 功能描述：验证 ControlBusFactory.encodeConnectionReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 CbCmd，并包含第三层请求负载。
    /// 参数：使用默认协议版本 0x02，Flag 让编码器自动选择。
    /// 返回值/用途：确保三层往返中的“请求编码”路径正确，为后续端到端联调打基础。
    test('encode connection request -> decode L1/L2/L3 content', () {
      final factory = ControlBusFactory();
      final bytes = factory.encodeConnectionReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.connectionRequest);

      // 第三层载荷应为 [protocolVersion]
      final l3 = l2.cbPayload;
      expect(l3, equals([0x02]));
    });

    /// 功能描述：构造“设备连接应答”的第三层载荷，包装为一层 AckOK，
    /// 经 ControlBusFactory.decodeConnectionRes 解码为业务模型并校验字段。
    /// 参数：型号 12 字节（ASCII，右侧补 0x00）、FW=0x0102、HW=0x0304、SN 三段 u32。
    /// 返回值/用途：验证工厂的“应答解码”路径正确处理 AckOK 与第三层负载。
    test('decode connection ack -> L3 model', () {
      // 组第三层载荷（28 字节，BE 序）
      final modelAscii = 'TT01-Model';
      final modelBytes = List<int>.from(modelAscii.codeUnits)
        ..addAll(List.filled(12 - modelAscii.length, 0x00));
      final fw = 0x0102; // 1.0.2 -> 0102
      final hw = 0x0304; // 3.0.4 -> 0304
      final sn1 = 1234567890;
      final sn2 = 987654321;
      final sn3 = 42;

      List<int> u16be(int v) => [(v >> 8) & 0xFF, v & 0xFF];
      List<int> u32be(int v) => [
            (v >> 24) & 0xFF,
            (v >> 16) & 0xFF,
            (v >> 8) & 0xFF,
            v & 0xFF,
          ];

      final l3 = <int>[
        ...modelBytes,
        ...u16be(fw),
        ...u16be(hw),
        ...u32be(sn1),
        ...u32be(sn2),
        ...u32be(sn3),
      ];

      // 包成一层 AckOK
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeConnectionRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.model, 'TT01-Model');
      expect(res.data!.firmwareVersion, '1.0.2');
      expect(res.data!.hardwareVersion, '3.0.4');
      // SN 拼接固定 10 位段宽（左补零）
      expect(res.data!.serialNumber.length, 30);
    });

    /// 功能描述：构造“电量状态应答”的第三层载荷（percent=85，statusByte=0x01 正在充电），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言枚举为 charging。
    /// 参数：percent=85，statusByte=0x01。
    /// 返回值/用途：验证 decodeBatteryStatusRes 的应答解析逻辑。
    test('decode battery status ack -> charging', () {
      final l3 = [85, 0x01];
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeBatteryStatusRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.batteryPercent, 85);
      expect(res.data!.chargeStatus, ChargeStatus.charging);
    });

    /// 功能描述：构造“功能模式应答”的第三层载荷（0x01 自平衡），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言枚举为 selfBalance。
    /// 参数：modeByte=0x01。
    /// 返回值/用途：验证 decodeOperatingModeRes 的应答解析逻辑。
    test('decode operating mode ack -> selfBalance', () {
      final l3 = [OperatingMode.selfBalance.value];
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeOperatingModeRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.mode, OperatingMode.selfBalance);
    });

    /// 功能描述：验证 ControlBusFactory.encodeElectricalMetricsReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 CbCmd，并包含第三层请求负载（空）。
    /// 返回值/用途：确保“电气参数请求”的编码路径正确。
    test('encode electrical metrics request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeElectricalMetricsReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.electricalMetricsRequest);
      expect(l2.cbPayload, isEmpty);
    });

    /// 功能描述：构造“电气参数应答”的第三层载荷（voltage=12000mV，current=500mA），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言字段。
    /// 参数：使用 u32 BE 编码两段数值。
    test('decode electrical metrics ack -> voltage/current parsed', () {
      List<int> u32be(int v) => [
            (v >> 24) & 0xFF,
            (v >> 16) & 0xFF,
            (v >> 8) & 0xFF,
            v & 0xFF,
          ];
      final l3 = <int>[...u32be(12000), ...u32be(500)];
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeElectricalMetricsRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.voltageMv, 12000);
      expect(res.data!.currentMa, 500);
    });

    /// 功能描述：验证 ControlBusFactory.encodeDeviceStatusReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 CbCmd，并包含第三层请求负载（空）。
    /// 返回值/用途：确保“设备状态请求”的编码路径正确。
    test('encode device status request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeDeviceStatusReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.deviceStatusRequest);
      expect(l2.cbPayload, isEmpty);
    });

    /// 功能描述：构造“设备状态应答”的第三层载荷（status=0xFF unknown，errorCode=0xDEADBEEF），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言字段。
    test('decode device status ack -> unknown + error code', () {
      List<int> u32be(int v) => [
            (v >> 24) & 0xFF,
            (v >> 16) & 0xFF,
            (v >> 8) & 0xFF,
            v & 0xFF,
          ];
      final l3 = <int>[DeviceStatus.unknown.value, ...u32be(0xDEADBEEF)];
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeDeviceStatusRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.deviceStatus, DeviceStatus.unknown);
      expect(res.data!.errorCode, 0xDEADBEEF);
    });

    /// 功能描述：验证 ControlBusFactory.encodeSpeedGearReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 CbCmd，并包含第三层请求负载（空）。
    test('encode speed gear request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeSpeedGearReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.speedGearRequest);
      expect(l2.cbPayload, isEmpty);
    });

    /// 功能描述：构造“速度档位应答”的第三层载荷（gear3），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言枚举为 gear3。
    test('decode speed gear ack -> gear3', () {
      final l3 = [SpeedGear.gear3.value];
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSpeedGearRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.gear, SpeedGear.gear3);
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSpeedControlAck 能正确解析为 Ack。
    test('decode set speed ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSpeedControlAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSetOperatingModeAck 能正确解析为 Ack。
    test('decode set operating mode ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSetOperatingModeAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSetSpeedGearAck 能正确解析为 Ack。
    test('decode set speed gear ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSetSpeedGearAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 功能描述：验证 ControlBusFactory.encodePlayHornReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 CbCmd，并包含第三层请求负载（u16 BE 毫秒）。
    test('encode play horn request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodePlayHornReq(durationMs: 1500);

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.hornControlRequest);
      expect(l2.cbPayload, equals([0x05, 0xDC])); // 1500 -> 0x05DC
    });

    /// 功能描述：构造空负载 AckOK，验证 decodePlayHornAck 能正确解析为 Ack。
    test('decode play horn ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodePlayHornAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSetJoystickAck 能正确解析为 Ack。
    test('decode set joystick ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSetJoystickAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSetPushRodSpeedAck 能正确解析为 Ack。
    test('decode set pushrod speed ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSetPushRodSpeedAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 功能描述：验证 ControlBusFactory.encodeSetFoldStateReq 的编码，并通过 L1/L2 解码检查 CbCmd 与第三层负载
    test('encode set fold state request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeSetFoldStateReq(state: FoldState.fold);

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.foldControlRequest);
      expect(l2.cbPayload, equals([FoldState.fold.value]));
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSetFoldStateAck 能正确解析为 Ack。
    test('decode set fold state ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSetFoldStateAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 负例：速度档位应答载荷长度不为 1 时应抛出 ArgumentError
    test('decode speed gear ack with invalid length throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x00, 0x01]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeSpeedGearRes(raw), throwsArgumentError);
    });

    /// 负例：设备状态应答载荷长度不为 5 时应抛出 ArgumentError
    test('decode device status ack with invalid length throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0xFF, 0x00, 0x00, 0x00]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeDeviceStatusRes(raw), throwsArgumentError);
    });

    /// 负例：Ack-only 应答带有非空第三层负载时应抛出 ArgumentError（以 SetSpeed 为例）
    test('decode set speed ack with non-empty payload throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x00]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeSpeedControlAck(raw), throwsArgumentError);
    });

    /// 负例：播放喇叭 Ack-only 应答带有非空第三层负载时应抛出 ArgumentError
    test('decode play horn ack with non-empty payload throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x00]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodePlayHornAck(raw), throwsArgumentError);
    });

    /// 负例：功能模式应答载荷长度不为 1 应抛出 ArgumentError
    test('decode operating mode ack with invalid length throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x00, 0x01]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeOperatingModeRes(raw), throwsArgumentError);
    });

    /// 负例：功能模式应答包含非法枚举值（0xFF）应抛出 ArgumentError
    test('decode operating mode ack with invalid mode value throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0xFF]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeOperatingModeRes(raw), throwsArgumentError);
    });

    /// 负例：电气参数应答载荷长度不为 8 应抛出 ArgumentError
    test('decode electrical metrics ack with invalid length throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: List<int>.filled(7, 0x00));
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeElectricalMetricsRes(raw), throwsArgumentError);
    });

    /// 功能描述：验证 ControlBusFactory.encodeDeviceLanguageReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 CbCmd，并包含第三层请求负载（空）。
    test('encode device language request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeDeviceLanguageReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.deviceLanguageRequest);
      expect(l2.cbPayload, isEmpty);
    });

    /// 功能描述：构造“获取设备语言应答”的第三层载荷（chinese=0x01），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言语言为 chinese。
    test('decode device language ack -> chinese', () {
      final l3 = [DeviceLanguage.chinese.value];
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeDeviceLanguageRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.language, DeviceLanguage.chinese);
    });

    /// 负例：设备语言应答载荷长度不为 1 时应抛出 ArgumentError
    test('decode device language ack with invalid length throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeDeviceLanguageRes(raw), throwsArgumentError);
    });

    /// 功能描述：验证 ControlBusFactory.encodeMuteStatusReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 CbCmd，并包含第三层请求负载（空）。
    test('encode mute status request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeMuteStatusReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.muteStatusRequest);
      expect(l2.cbPayload, isEmpty);
    });

    /// 功能描述：构造“获取静音状态应答”的第三层载荷（off=0x00），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言状态为 off。
    test('decode mute status ack -> off', () {
      final l3 = [MuteState.off.value];
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: l3);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeMuteStatusRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.state, MuteState.off);
    });

    /// 负例：静音状态应答载荷长度不为 1 时应抛出 ArgumentError
    test('decode mute status ack with invalid length throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x00, 0x01]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeMuteStatusRes(raw), throwsArgumentError);
    });

    /// 功能描述：验证 ControlBusFactory.encodeSetDeviceLanguageReq 的编码，并通过 L1/L2 解码检查 CbCmd 与第三层负载
    test('encode set device language request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeSetDeviceLanguageReq(language: DeviceLanguage.english);

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.deviceLanguageControlRequest);
      expect(l2.cbPayload, equals([DeviceLanguage.english.value]));
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSetDeviceLanguageAck 能正确解析为 Ack。
    test('decode set device language ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSetDeviceLanguageAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 负例：设置设备语言 Ack-only 应答带有非空第三层负载时应抛出 ArgumentError
    test('decode set device language ack with non-empty payload throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x01]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeSetDeviceLanguageAck(raw), throwsArgumentError);
    });

    /// 功能描述：验证 ControlBusFactory.encodeSetMuteStatusReq 的编码，并通过 L1/L2 解码检查 CbCmd 与第三层负载
    test('encode set mute status request -> decode L1/L2/L3 content', () {
      final bytes = ControlBusFactory().encodeSetMuteStatusReq(state: MuteState.on);

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.normal);

      final l2 = ControlBusDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.cbCmd, CbCmd.muteControlRequest);
      expect(l2.cbPayload, equals([MuteState.on.value]));
    });

    /// 功能描述：构造空负载 AckOK，验证 decodeSetMuteStatusAck 能正确解析为 Ack。
    test('decode set mute status ack -> ack-only', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const []);
      final raw = InterChipEncoder().encode(ack);

      final res = ControlBusFactory().decodeSetMuteStatusAck(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
    });

    /// 负例：设置静音状态 Ack-only 应答带有非空第三层负载时应抛出 ArgumentError
    test('decode set mute status ack with non-empty payload throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x01]);
      final raw = InterChipEncoder().encode(ack);
      expect(() => ControlBusFactory().decodeSetMuteStatusAck(raw), throwsArgumentError);
    });
  });

  group('DfuFactory integration', () {
    /// 功能描述：验证 DfuFactory.encodeGetDeviceInfoReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 DfuCmd，并包含第三层请求负载（空）。
    /// 参数：默认 DFU 版本 0x01。
    /// 返回值/用途：确保“DFU 获取设备信息请求编码”路径正确。
    test('encode get device info request -> decode L1/L2/L3 content', () {
      final factory = DfuFactory();
      final bytes = factory.encodeGetDeviceInfoReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.dfu);

      final l2 = DfuDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.dfuCmd, DfuCmd.getDeviceInfo);
      expect(l2.dfuVersion, 0x01);

      // 第三层负载为空
      expect(l2.dfuPayload, isEmpty);
    });

    /// 功能描述：验证 DfuFactory.encodeStartUpgradeReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 DfuCmd，并包含第三层请求负载（空）。
    /// 参数：默认 DFU 版本 0x01。
    /// 返回值/用途：确保三层往返中的“DFU 开始升级请求编码”路径正确。
    test('encode start upgrade request -> decode L1/L2/L3 content', () {
      final factory = DfuFactory();
      final bytes = factory.encodeStartUpgradeReq();

      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.dfu);

      final l2 = DfuDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.dfuCmd, DfuCmd.startUpgrade);
      expect(l2.dfuVersion, 0x01);

      // 第三层负载为空
      expect(l2.dfuPayload, isEmpty);
    });

    /// 功能描述：构造“开始升级应答”的第三层载荷（pkgVersion=0x01，opResult=0x00 成功），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言字段。
    /// 参数：payload=[0x01, 0x00]。
    /// 返回值/用途：验证 decodeStartUpgradeRes 的应答解析逻辑。
    test('decode start upgrade ack -> success', () {
      // 第三层载荷：pkgVersion=0x01，opResult=0x00
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: [0x01, 0x00]);
      final raw = InterChipEncoder().encode(ack);

      final res = DfuFactory().decodeStartUpgradeRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.dfuPkgVersion, 0x01);
      expect(res.data!.dfuOpResult, 0x00);
    });

    /// 功能描述：构造“完成升级应答”的第三层载荷（pkgVersion=0x01，opResult=0x00 成功），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言字段。
    /// 参数：payload=[0x01, 0x00]。
    /// 返回值/用途：验证 decodeFinishUpgradeRes 的应答解析逻辑。
    test('decode finish upgrade ack -> success', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: [0x01, 0x00]);
      final raw = InterChipEncoder().encode(ack);

      final res = DfuFactory().decodeFinishUpgradeRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.dfuPkgVersion, 0x01);
      expect(res.data!.dfuOpResult, 0x00);
    });

    /// 功能描述：验证 DfuFactory.encodeWriteUpgradeChunkReq 生成的一层字节流，
    /// 能被第一层与第二层解码为预期的 Cmd 与 DfuCmd，并包含第三层负载（DfuBlob 头 + 数据）。
    /// 参数：构造 pageId=1, blobId=2, blobStart=3, blobData=[0xAA, 0xBB, 0xCC]。
    /// 返回值/用途：确保 DFU 写块请求的编码与三层字段顺序正确（大端序）。
    test('encode write upgrade chunk request -> decode and validate header', () {
      final blob = DfuBlob(
        pageId: 1,
        blobId: 2,
        blobStart: 3,
        blobData: const [0xAA, 0xBB, 0xCC],
      );

      final bytes = DfuFactory().encodeWriteUpgradeChunkReq(blob: blob);
      final l1 = InterChipDecoder().decode(bytes);
      expect(l1, isNotNull);
      expect(l1!.cmd, InterChipCmds.dfu);

      final l2 = DfuDecoder().decode(l1.payload);
      expect(l2, isNotNull);
      expect(l2!.dfuCmd, DfuCmd.writeUpgradeChunk);
      expect(l2.dfuVersion, 0x01);

      final l3 = l2.dfuPayload;
      // 头部：pageId(u16 BE), blobId(u16 BE), blobSize(u16 BE), blobStart(u16 BE)
      expect(l3.sublist(0, 2), equals([0x00, 0x01]));
      expect(l3.sublist(2, 4), equals([0x00, 0x02]));
      expect(l3.sublist(4, 6), equals([0x00, 0x03])); // blobSize=3
      expect(l3.sublist(6, 8), equals([0x00, 0x03]));
      expect(l3.sublist(8), equals([0xAA, 0xBB, 0xCC]));
    });

    /// 功能描述：构造“写升级包应答”的第三层载荷（pkgVersion=0x01，status=0x00 成功），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言字段。
    /// 参数：payload=[0x01, 0x00]。
    /// 返回值/用途：验证 decodeWriteUpgradeChunkRes 的应答解析逻辑。
    test('decode write upgrade chunk ack -> success', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: [0x01, 0x00]);
      final raw = InterChipEncoder().encode(ack);

      final res = DfuFactory().decodeWriteUpgradeChunkRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.dfuPkgVersion, 0x01);
      expect(res.data!.result.value, 0x00);
    });

    /// 功能描述：构造“获取设备信息应答”的第三层载荷（33 字节，均为 BE），
    /// 包装为 AckOK 后由工厂解码为业务模型，并断言字段与 ROM 版本格式。
    test('decode get device info ack -> full fields parsed', () {
      final payload = <int>[
        // DfuPkgVersion u8
        0x01,
        // BootloaderVersion u16
        0x00, 0x02,
        // BootloaderPageCnt u16
        0x00, 0x03,
        // DeviceType u16
        0x01, 0x04,
        // PageNum u32
        0x00, 0x00, 0x00, 0x05,
        // PageSize u32
        0x00, 0x00, 0x10, 0x00,
        // RomVersion u32 -> [b0,b1,b2,b3] => 2.3.04
        0x00, 0x02, 0x03, 0x04,
        // VenderInfo u32
        0x00, 0x00, 0x00, 0x06,
        // HardwareVersion u16
        0x00, 0x07,
        // DfuDeviceFlag u32
        0x00, 0x00, 0x00, 0x08,
        // DfuDevicePowerVolt u32
        0x00, 0x00, 0x12, 0x34,
      ];

      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: payload);
      final raw = InterChipEncoder().encode(ack);

      final res = DfuFactory().decodeGetDeviceInfoRes(raw);
      expect(res.status, InterChipCmds.ackOk);
      expect(res.data, isNotNull);
      expect(res.data!.dfuPkgVersion, equals(const [0x01]));
      expect(res.data!.bootloaderVersion, equals(const [0x00, 0x02]));
      expect(res.data!.bootloaderPageCnt, equals(const [0x00, 0x03]));
      expect(res.data!.deviceType, equals(const [0x01, 0x04]));
      expect(res.data!.pageNum, equals(const [0x00, 0x00, 0x00, 0x05]));
      expect(res.data!.pageSize, equals(const [0x00, 0x00, 0x10, 0x00]));
      expect(res.data!.romVersion, equals('2.3.04'));
      expect(res.data!.venderInfo, equals(const [0x00, 0x00, 0x00, 0x06]));
      expect(res.data!.hardwareVersion, equals(const [0x00, 0x07]));
      expect(res.data!.dfuDeviceFlag, equals(const [0x00, 0x00, 0x00, 0x08]));
      expect(res.data!.dfuDevicePowerVolt, equals(const [0x00, 0x00, 0x12, 0x34]));
    });

    /// 负例：获取设备信息应答载荷长度不足 33 时应抛出 ArgumentError
    test('decode get device info ack with invalid length throws', () {
      final ack = InterChipPacket(cmd: InterChipCmds.ackOk, payload: List<int>.filled(32, 0x01));
      final raw = InterChipEncoder().encode(ack);
      expect(() => DfuFactory().decodeGetDeviceInfoRes(raw), throwsArgumentError);
    });

    /// 边界：若一层 Cmd 非 AckOK，应返回对应状态且 data 为 null
    test('decode get device info with non-AckOK returns status-only', () {
      // 构造 DFU 普通报文（非 AckOK），负载内容对该场景无意义
      final packet = InterChipPacket(cmd: InterChipCmds.dfu, payload: const [0x00]);
      final raw = InterChipEncoder().encode(packet);

      final res = DfuFactory().decodeGetDeviceInfoRes(raw);
      expect(res.status, InterChipCmds.dfu);
      expect(res.data, isNull);
    });
  });
}
