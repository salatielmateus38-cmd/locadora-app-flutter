/// Formata um valor em reais: 1159.6 -> "R$ 1.159,60".
String formatCurrency(double value) {
  final negative = value < 0;
  final cents = (value.abs() * 100).round();
  final integer = (cents ~/ 100).toString();
  final decimals = (cents % 100).toString().padLeft(2, '0');
  final buffer = StringBuffer();
  for (var i = 0; i < integer.length; i++) {
    if (i > 0 && (integer.length - i) % 3 == 0) buffer.write('.');
    buffer.write(integer[i]);
  }
  return '${negative ? '-' : ''}R\$ $buffer,$decimals';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 05/03/2026
String formatDate(DateTime date) => '${_two(date.day)}/${_two(date.month)}/${date.year}';

/// 05/03/2026 14:30
String formatDateTime(DateTime date) => '${formatDate(date)} ${_two(date.hour)}:${_two(date.minute)}';

String pluralDays(int days) => '$days diária${days == 1 ? '' : 's'}';
