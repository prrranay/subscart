enum OrderStatus {
  scheduled,
  skipped,
  swapped,
  moved,
  rescheduled;

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'skipped':
        return OrderStatus.skipped;
      case 'swapped':
        return OrderStatus.swapped;
      case 'moved':
        return OrderStatus.moved;
      case 'rescheduled':
        return OrderStatus.rescheduled;
      case 'scheduled':
      default:
        return OrderStatus.scheduled;
    }
  }

  String toJson() => name;
}
