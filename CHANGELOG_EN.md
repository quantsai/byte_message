# Changelog (English)

All notable changes to this project will be documented in this file.

## 1.3.1 — Patch release

- Docs: Updated README (dependency version to ^1.3.1, new coverage section)
- Docs: Updated CHANGELOG with 1.3.1 notes
- Build: Version bump in pubspec.yaml to 1.3.1
- Tests: Verified all tests passed; dry-run publish succeeded locally
- Repo housekeeping: Added .pubignore; stopped tracking coverage/HTML in Git to avoid publish warnings
- Examples: Restructured to follow Dart’s official package layout (example/main.dart) and added function-level comments

## 1.3.0 — Feature release

- Protocol: Completed Layer 1 encoder/decoder with checksum toggle and long-frame support
- Control Bus: Added Layer 2 commands and business models for device info, battery/charging, connection, etc.
- DFU: Added Layer 2 commands and Layer 3 models for upgrade start/write/finish with chunking
- Factories: Added ControlBusFactory and DfuFactory for one-step Layer3→Layer2→Layer1 operations
- Utils: Added PacketUtils for analysis, debug strings, and hex helpers
- Tests: Added extensive unit tests covering L1/L2/L3

## 1.2.x — Improvements

- Performance: Optimized encoders and small allocations
- Stability: Improved edge-case decoding and validation
- Docs: Expanded usage guides and examples

## 1.1.x — Maintenance

- Refactor: Cleaned up models and constants; improved naming
- Tests: Increased coverage and added CI scripts

## 1.0.0 — Initial release

- Base: Inter-chip protocol framing (short/long), checksum, command codes
- Control Bus & DFU scaffolding
- Basic examples and README

---

Language switch: 中文版更新日志 → [CHANGELOG.md](CHANGELOG.md)

## 1.4.0 — Minor release with API updates (2025-11-18)

### API updates

- Layer 2 models now use enhanced enums for subcommands:
  - Control Bus: `ControlBusMessage.cbCmd: int -> CbCmd`
  - DFU: `DfuMessage.dfuCmd: int -> DfuCmd`
- Encoders updated to use `enum.code` when writing bytes:
  - `ControlBusEncoder` / `DfuEncoder`
- Decoding and models updated to map bytes via `CbCmd.fromCode` / `DfuCmd.fromCode`.
  Unknown codes return `null` from `fromBytes`.

### Migration guide

1. Replace plain integers with enums when constructing Layer 2 models:
   - Old: `ControlBusMessage(cbCmd: 0x30, ...)`
   - New: `ControlBusMessage(cbCmd: CbCmd.batteryStatusRequest, ...)`
   - Old: `DfuMessage(dfuCmd: 0x02, ...)`
   - New: `DfuMessage(dfuCmd: DfuCmd.startUpgrade, ...)`
2. For printing/asserting command codes, use the enum’s `code`:
   - `msg.cbCmd.code.toRadixString(16)` / `msg.dfuCmd.code`
3. Decoders may return `null` if encountering unknown subcommand codes; handle nulls accordingly.
4. Enums are exported from the public entry now:
   - `package:byte_message/byte_message.dart` (new export)
     Or via internal paths if needed.

### Docs & examples

- README updated to `^1.4.0` and sample code uses enums and `.code`.
- Added root-level "说明文档.md" (Chinese project doc) with planning, execution steps and progress.

### QA

- `dart analyze` (No issues found)
- `dart test -r expanded` (All tests passed)
