import 'package:intl/intl.dart';

final _dateKeyFormat = DateFormat('yyyy-MM-dd');

String dateToKey(DateTime date) => _dateKeyFormat.format(date);
