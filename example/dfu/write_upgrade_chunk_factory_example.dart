/// 示例：写升级包（Write Upgrade Chunk）
///
/// 本示例展示如何使用 DfuFactory 将第三层 DfuBlob 编码为完整的一层数据包，
/// 并演示模拟 AckOK 应答后，如何解码第三层的 WriteUpgradeChunkRes。
import 'package:byte_message/byte_message.dart';

void main() {
  final factory = DfuFactory();

  // 构造一个 DfuBlob：PageId=1, BlobId=1, BlobStart=0，数据为 5 字节
  final blob = DfuBlob(
    pageId: 1,
    blobId: 1,
    blobStart: 0,
    blobData: const [0xDE, 0xAD, 0xBE, 0xEF, 0x01],
  );

  // 编码写升级包请求（第二层 DfuCmd=0x05，第三层载荷为 DfuBlob）
  final l1ReqBytes = factory.encodeWriteUpgradeChunkReq(
    blob: blob,
  );

  // 模拟 AckOK 应答：第三层负载为 [dfuPkgVersion=0x01, dfuOpResult=0x00]
  final simulatedAckOk = InterChipEncoder().encode(
    InterChipPacket(
      cmd: InterChipCmds.ackOk,
      payload: const [0x01, 0x01],
    ),
  );

  final decoded = factory.decodeWriteUpgradeChunkRes(simulatedAckOk);
  print('WriteUpgradeChunk Res data: ${decoded.data?.result}');
}
