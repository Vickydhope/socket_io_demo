extension IntToDate on int {
  DateTime get toDate {
    return DateTime.fromMillisecondsSinceEpoch(this);
  }
}
