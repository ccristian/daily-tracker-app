import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/data/database_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabaseFactory();
  runApp(const ProviderScope(child: BonoraApp()));
}
