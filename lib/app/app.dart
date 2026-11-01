import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logomedo_app/app/router.dart';
import 'package:logomedo_app/app/tema.dart';

class LogoMedoApp extends ConsumerWidget {
  const LogoMedoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'LogoMedo',
        debugShowCheckedModeBanner: false,
        theme: tema(Brightness.light),
        darkTheme: tema(Brightness.dark),
        routerConfig: ref.watch(routerProvider),
        locale: const Locale('hr'),
      );
}
