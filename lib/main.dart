import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/progress_repository.dart';
import 'services/haptics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await PrefsProgressRepository.open();
  runApp(KebritApp(repository: repository, haptics: const SystemHaptics()));
}
