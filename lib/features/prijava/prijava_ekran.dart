import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logomedo_app/core/konfig.dart';
import 'package:logomedo_app/core/prijava.dart';

class PrijavaEkran extends ConsumerWidget {
  const PrijavaEkran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stanje = ref.watch(prijavaProvider);
    final t = Theme.of(context).textTheme;
    final poruka = stanje is Odjavljen ? stanje.poruka : null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('LogoMedo', style: t.displaySmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Prijava ide kroz preglednik: passkey ili kod na e-mail, isto kao na webu.', style: t.bodyMedium),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: stanje is Ucitava ? null : () => ref.read(prijavaProvider.notifier).prijaviSe(),
                    child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Prijavi se')),
                  ),
                  if (poruka != null) ...[
                    const SizedBox(height: 16),
                    Text(poruka, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  if (kDebugMode && lokalniServer) ...[const SizedBox(height: 32), const _DevToken()],
                  const SizedBox(height: 24),
                  Text(Uri.parse(apiUrl).host, style: t.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Samo debug + lokalni wrangler: Access lokalno ne radi, token daje `scripts/app-token.sh`.
class _DevToken extends ConsumerStatefulWidget {
  const _DevToken();
  @override
  ConsumerState<_DevToken> createState() => _DevTokenState();
}

class _DevTokenState extends ConsumerState<_DevToken> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: TextField(controller: _c, decoration: const InputDecoration(labelText: 'Dev token (scripts/app-token.sh)'))),
          IconButton(onPressed: () => ref.read(prijavaProvider.notifier).prijaviTokenom(_c.text), icon: const Icon(Icons.login)),
        ],
      );
}
