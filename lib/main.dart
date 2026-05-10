import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/config/supabase_runtime.dart';
import 'core/constants/app_env_keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();

  const definedSupabaseUrl = String.fromEnvironment(AppEnvKeys.supabaseUrl);
  const definedSupabaseAnonKey = String.fromEnvironment(
    AppEnvKeys.supabaseAnonKey,
  );
  final supabaseUrl = _normalizeSupabaseUrl(
    definedSupabaseUrl.isNotEmpty
        ? definedSupabaseUrl
        : dotenv.env[AppEnvKeys.supabaseUrl] ?? '',
  );
  final supabaseAnonKey = _normalizeSupabaseAnonKey(
    definedSupabaseAnonKey.isNotEmpty
        ? definedSupabaseAnonKey
        : dotenv.env[AppEnvKeys.supabaseAnonKey] ?? '',
  );

  if (_isRealSupabaseConfig(supabaseUrl, supabaseAnonKey)) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    SupabaseRuntime.isConfigured = true;
    SupabaseRuntime.supabaseUrl = supabaseUrl;
  }

  runApp(const ProviderScope(child: AiDiarySocialApp()));
}

String _normalizeSupabaseUrl(String url) {
  return url
      .trim()
      .replaceAll('rijmcclfmgrdpdcppixa', 'rijmcclfmgdrpdcppixa')
      .replaceAll('rijmcclfmgdrpdcppixa', 'eqcklgzjoaakxslotvqx')
      .replaceAll(RegExp(r'/rest/v1/?$'), '');
}

String _normalizeSupabaseAnonKey(String anonKey) {
  return anonKey.trim().replaceAll(
    'sb_publishable_OP8Fpt5O6nKwsAFhFTZXRA_lXjiJ10I',
    'sb_publishable_PATcDtVZv-BPRDac-4COtw_BrAPQss2',
  );
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }
}

bool _isRealSupabaseConfig(String url, String anonKey) {
  return url.startsWith('https://') &&
      url.contains('.supabase.co') &&
      anonKey.isNotEmpty &&
      !url.contains('your-project-ref') &&
      !anonKey.contains('your-public-anon-key');
}
