class ReaderConfig {
  final int deviceNum;
  final int spiNum;
  final int rstPin;

  const ReaderConfig({
    required this.deviceNum,
    required this.spiNum,
    required this.rstPin,
  });
}

class RFIDEvent {
  final int readerNum;
  final int? tagId;
  final String? error;
  final DateTime timestamp;

  RFIDEvent({
    required this.readerNum,
    this.tagId,
    this.error,
  }) : timestamp = DateTime.now();

  bool get isError => error != null;
  bool get hasTag => tagId != null;

  @override
  String toString() {
    if (isError) {
      return 'Reader $readerNum Error: $error';
    } else if (hasTag) {
      return 'Reader $readerNum detected tag: $tagId';
    } else {
      return 'Reader $readerNum: No tag detected';
    }
  }
}
