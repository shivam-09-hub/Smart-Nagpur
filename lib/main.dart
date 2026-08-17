import 'package:flutter/material.dart';
import 'package:smart_nagpur/app.dart';
import 'package:smart_nagpur/core/config/config.dart';
import 'package:smart_nagpur/data/data.dart';
import 'package:smart_nagpur/state/app_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = SupabaseConfig.fromEnvironment();
  config.validate();
  await Supabase.initialize(
    url: config.projectUrl,
    publishableKey: config.publishableKey,
    debug: false,
  );

  final client = Supabase.instance.client;
  final authGateway = SupabaseAuthGateway(client);
  final fileGateway = SupabaseFileGateway(client);
  final controller = AppController(
    authGateway: authGateway,
    remoteDataGateway: SupabaseRemoteDataGateway(client, fileGateway),
    clearLocalSensitiveFiles: fileGateway.clearLocalSensitiveFiles,
  );
  runApp(SmartNagpurApp(controller: controller));
}
