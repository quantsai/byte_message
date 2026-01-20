# Byte Message - Inter-chip Communication Protocol Library

Chinese README: see [README_CN.md](README_CN.md)

## Overview

Byte Message implements an inter-chip binary protocol supporting short and long frames with optional checksum. It provides:

- Layer 1 (Link layer) framing and parsing
- Layer 2 payload encoders/decoders (Control Bus and DFU)
- Optional Layer 3 business models and factories

### Packet formats

Short frame (total length ≤ 255 bytes):

| Flag | Len | Cmd | Payload | [Checksum] |
| ---- | --- | --- | ------- | ---------- |
| 1B   | 1B  | 1B  | N B     | [1B]       |

Long frame (total length > 255 bytes):

| Flag | Len | LenH | Cmd | Payload | [Checksum] |
| ---- | --- | ---- | --- | ------- | ---------- |
| 1B   | 1B  | 1B   | 1B  | N B     | [1B]       |

### Flag bits

| Bit 7   | Bit 6      | Bit 5   | Bit 4       | Bit 3   | Bit 2   | Bit 1   | Bit 0   |
| ------- | ---------- | ------- | ----------- | ------- | ------- | ------- | ------- |
| reserve | Long Frame | reserve | Checksum ON | reserve | reserve | reserve | reserve |

- Bit 4 (Checksum): 1 = enable checksum, 0 = disable
- Bit 6 (Long Frame): 1 = long frame, 0 = short frame
- Others: reserved (set to 0)

### Supported commands

- `0xF8`: NORMAL — general communication
- `0x20`: DFU — device firmware upgrade

## Getting started

### Install

Add the dependency in `pubspec.yaml`:

```yaml
dependencies:
  byte_message: ^1.7.0
```

Then run:

```bash
dart pub get
# Or for Flutter projects
flutter pub get
```

### Basic usage (factories)

Use factories to perform Layer3 → Layer2 → Layer1 framing or parsing in one step.

```dart
import 'package:byte_message/byte_message.dart';

void main() {
  // Control Bus: request battery/charging status
  final cbFactory = ControlBusFactory();
  final l1BatteryReq = cbFactory.encodeBatteryStatusReq();
  print('BatteryStatus Req L1 bytes: ${l1BatteryReq.map((b) => b.toRadixString(16).padLeft(2, '0')).toList()}');

  // Simulate device AckOK (payload is layer-3 data, here 2 bytes for demo)
  final simulatedAck = InterChipEncoder().encode(
    InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x64, 0x01]),
  );
  final batteryRes = cbFactory.decodeBatteryStatusRes(simulatedAck);
  print('BatteryStatus decoded: ${batteryRes.data}');

  // DFU: start upgrade
  final dfuFactory = DfuFactory();
  final l1StartReq = dfuFactory.encodeStartUpgradeReq();
  print('StartUpgrade Req L1 bytes: ${l1StartReq.map((b) => b.toRadixString(16).padLeft(2, '0')).toList()}');
  final simulatedDfuAck = InterChipEncoder().encode(
    InterChipPacket(cmd: InterChipCmds.ackOk, payload: const [0x01, 0x00]),
  );
  final startRes = dfuFactory.decodeStartUpgradeRes(simulatedDfuAck);
  print('StartUpgrade isOk: ${startRes.data?.isOk}');
}
```

## Example structure

This package follows Dart’s package layout convention for examples:

- Main example entry: `example/main.dart` — run with `dart run example/main.dart`
- Advanced examples:
  - Control Bus: `example/control_bus/*.dart`
  - DFU: `example/dfu/*.dart`

Start with the main example, then explore advanced ones as needed.

## Layered usage (L1 / L2 / L3)

Data flow:

- Encode: Layer3 (business objects → business bytes) → used as Layer2 payload → used as Layer1 payload for framing
- Decode: Layer1 (deframe to payload) → Layer2 (parse subcommand bytes) → Layer3 (restore business objects)

Responsibilities:

- Layer1 (Inter-chip frame): framing, command code, length, checksum; treats payload as opaque bytes
- Layer2 (Control Bus / DFU): subcommand + its payload; independent of Layer1 details
- Layer3 (business payload): business fields and byte layouts; independent of lower layers

### Layer1 only demo

```dart
import 'package:byte_message/byte_message.dart';

void main() {
  final encoder = InterChipEncoder();
  final decoder = InterChipDecoder();

  final transparentPayload = const [0xAA, 0xBB, 0xCC];

  final packet = InterChipPacket(
    flag: 0x10, // checksum ON
    cmd: InterChipCmds.normal,
    payload: transparentPayload,
  );
  final encoded = encoder.encode(packet);
  print('Layer1 encoded bytes: ${encoded?.map((b) => b.toRadixString(16).padLeft(2, '0')).toList()}');

  final decoded = decoder.decode(encoded);
  if (decoded != null) {
    print('Layer1 decoded cmd: 0x${decoded.cmd.toRadixString(16)}');
    print('Layer1 decoded payload: ${decoded.payload}');
  }
}
```

### Layer2 only demo (Control Bus & DFU)

```dart
import 'package:byte_message/byte_message.dart';

void main() {
  // Control Bus
  final l2Cb = ControlBusMessage(cbCmd: CbCmd.deviceStatusRequest, cbPayload: const []);
  final cbBytes = ControlBusEncoder().encode(l2Cb);
  print('Layer2 ControlBus encoded: ${cbBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList()}');
  final cbMsg = ControlBusDecoder().decode(cbBytes);
  print('Layer2 ControlBus decoded cmd: 0x${cbMsg?.cbCmd.code.toRadixString(16)}, payload: ${cbMsg?.cbPayload}');

  // DFU
  final l2Dfu = DfuMessage(dfuCmd: DfuCmd.startUpgrade, dfuVersion: 0x01, dfuPayload: const []);
  final dfuBytes = DfuEncoder().encode(l2Dfu);
  print('Layer2 DFU encoded: ${dfuBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).toList()}');
  final dfuMsg = DfuDecoder().decode(dfuBytes);
  print('Layer2 DFU decoded cmd: 0x${dfuMsg?.dfuCmd.code.toRadixString(16)}, ver: ${dfuMsg?.dfuVersion}, payload: ${dfuMsg?.dfuPayload}');
}
```

### Layer3 only demo (business payload)

```dart
import 'package:byte_message/byte_message.dart';

void main() {
  // Control Bus: device connection request/response
  final connReq = GetDeviceConnectionReq(protocolVersion: 0x02);
  final connReqBytes = connReq.encode();
  print('Layer3 ConnectionReq encoded: ${connReqBytes}');

  final connResBytes = List<int>.filled(28, 0x00);
  final connRes = GetDeviceConnectionRes.fromBytes(connResBytes);
  print('Layer3 ConnectionRes decoded -> model=${connRes.model}, fw=${connRes.firmwareVersion}, hw=${connRes.hardwareVersion}');

  // DFU: write upgrade chunk
  final blob = DfuBlob(pageId: 1, blobId: 1, blobStart: 0, blobData: const [0xDE, 0xAD, 0xBE]);
  final writeReq = WriteUpgradeChunkReq(blob: blob);
  final writeReqBytes = writeReq.encode();
  print('Layer3 WriteUpgradeChunkReq encoded: ${writeReqBytes}');

  final writeRes = WriteUpgradeChunkRes.fromBytes(const [0x01, 0x00]);
  print('Layer3 WriteUpgradeChunkRes decoded -> dfuPkgVersion=${writeRes.dfuPkgVersion}, isOk=${writeRes.isOk}');
}
```

## Coverage & LCOV

Current coverage: 76.0% (823/1083 lines), 38 source files.

Reports:

- Text: `coverage/lcov.info`
- HTML: `coverage/html/index.html`

Generate and view (macOS):

```bash
./run_tests.sh coverage
# Or manual:
# dart test -r compact
# genhtml coverage/lcov.info --output-directory coverage/html --branch-coverage --title "byte_message coverage" --legend
```

LCOV usage:

```bash
brew install lcov
lcov --summary coverage/lcov.info
lcov --list coverage/lcov.info
genhtml coverage/lcov.info --output-directory coverage/html --branch-coverage --title "byte_message coverage" --legend
```

Tips:

- Green: hit, Red: missed, Yellow: partial
- Navigate directories (utils/factories/protocols/models) to drill into files
- Low-coverage priorities: inter_chip_models.dart, control_bus_factory.dart, dfu_models.dart

## Testing

Run all tests:

```bash
dart test
```

Generate coverage:

```bash
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

## Debugging tools

Packet analysis:

```dart
final rawData = [0x10, 0x04, 0xF8, 0x01, 0x02, 0x03, 0x1E];
final analysis = PacketUtils.analyzePacket(rawData);
print(analysis);
```

Debug info:

```dart
final debugInfo = PacketUtils.generateDebugInfo(rawData);
print(debugInfo);
```

Formatting helpers:

```dart
final formatted = PacketUtils.formatBytes([0x10, 0x04, 0xF8], ':');
final bytes = PacketUtils.parseHexString("10 04 F8");
```

## Performance

- Short frame encode: ~0.1ms (typical 10-byte payload)
- Long frame encode: ~0.5ms (typical 1KB payload)
- Batch encode: 10,000+ packets per second

## Contribution

Pull requests are welcome. Please ensure:

1. All tests pass
2. Code follows Dart style guide
3. Add proper documentation comments

---

Language switch: 中文版 README → [README.md](README.md)
