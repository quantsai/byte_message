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
