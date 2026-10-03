class CurrencyFormat {
  /// Formats numbers to Pakistani Rupees format: Rs. 1,299 / Rs. 14,999 / Rs. 289,999
  static String format(num amount) {
    final int intAmount = amount.round();
    final isNegative = intAmount < 0;
    final absAmount = intAmount.abs();
    final str = absAmount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return isNegative ? '-Rs. $formatted' : 'Rs. $formatted';
  }
}
