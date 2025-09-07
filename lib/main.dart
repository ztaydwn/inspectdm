import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/metadata_service.dart';
import 'providers/config_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios
  final meta = MetadataService();
  await meta.init();

  final configProvider = ConfigProvider();
  await configProvider.loadConfig();

  runApp(InspectWApp(meta: meta, configProvider: configProvider));
}

class InspectWApp extends StatelessWidget {
  final MetadataService meta;
  final ConfigProvider configProvider;
  const InspectWApp(
      {super.key, required this.meta, required this.configProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MetadataService>.value(value: meta),
        ChangeNotifierProvider<ConfigProvider>.value(value: configProvider),
      ],
      child: MaterialApp(
        title: 'InspectW Camera Custom',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 0, 131, 155)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
