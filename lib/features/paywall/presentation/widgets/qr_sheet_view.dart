class QrSheetView {
  const QrSheetView({required this.data, this.expired = false, this.remaining});

  final String data;
  final bool expired;
  final Duration? remaining;
}
