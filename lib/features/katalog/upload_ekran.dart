import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logomedo_app/core/api.dart';
import 'package:logomedo_app/core/modeli.dart';
import 'package:logomedo_app/features/katalog/katalog_repo.dart';

const _maxBajtova = 8 * 1024 * 1024; // isto kao MAX_BAJTOVA na serveru
const _mime = {'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'webp': 'image/webp'};

/// Slika iz vanjskog alata (Gemini, Leonardo…) s promptom kako je nastala. Ulazi kao kandidat.
/// Bira se kroz sistemski Photo Picker (bez dozvole za cijelu galeriju), šalje se original.
class UploadEkran extends ConsumerStatefulWidget {
  const UploadEkran({required this.rijec, super.key});
  final RijecDetalj rijec;

  @override
  ConsumerState<UploadEkran> createState() => _UploadEkranState();
}

class _UploadEkranState extends ConsumerState<UploadEkran> {
  final _prompt = TextEditingController();
  final _alat = TextEditingController(text: 'Gemini');
  XFile? _datoteka;
  int? _bajtova;
  late String _stil = ref.read(stilProvider);
  double? _napredak;
  String? _greska;

  Future<void> _odaberi() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, requestFullMetadata: false);
    if (f == null) return;
    final n = await f.length();
    setState(() {
      _datoteka = f;
      _bajtova = n;
      _greska = n > _maxBajtova ? 'Slika je veća od 8 MB.' : null;
    });
  }

  String? get _mimeDatoteke => _mime[_datoteka?.path.split('.').last.toLowerCase()];

  Future<void> _posalji() async {
    final f = _datoteka;
    final mime = _mimeDatoteke;
    if (f == null || mime == null || _prompt.text.trim().isEmpty || (_bajtova ?? 0) > _maxBajtova) return;
    setState(() {
      _napredak = 0;
      _greska = null;
    });
    try {
      await ref.read(katalogRadnjeProvider).ucitajSliku(
            rijecId: widget.rijec.id,
            putanja: f.path,
            mime: mime,
            stil: _stil,
            prompt: _prompt.text.trim(),
            alat: _alat.text.trim(),
            napredak: (p) => setState(() => _napredak = p),
          );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      setState(() {
        _napredak = null;
        _greska = porukaGreske(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final katalog = ref.watch(katalogProvider).value;
    final salje = _napredak != null;
    final f = _datoteka;
    final spremno = f != null && _mimeDatoteke != null && _prompt.text.trim().isNotEmpty && (_bajtova ?? 0) <= _maxBajtova && !salje;
    return Scaffold(
      appBar: AppBar(title: Text('Slika: ${widget.rijec.rijec.toUpperCase()}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: salje ? null : _odaberi,
                child: f == null
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.photo_library_outlined, size: 48), SizedBox(height: 8), Text('Odaberi iz galerije')]))
                    : ColoredBox(color: Colors.white, child: Image.file(File(f.path), fit: BoxFit.contain)),
              ),
            ),
          ),
          if (f != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${f.name} · ${((_bajtova ?? 0) / 1024).round()} KB${_mimeDatoteke == null ? ' · nepodržan format (PNG, JPEG, WebP)' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          if (katalog != null)
            SegmentedButton<String>(
              segments: [for (final s in katalog.stilovi) ButtonSegment(value: s.kod, label: Text(s.naziv))],
              selected: {_stil},
              onSelectionChanged: salje ? null : (v) => setState(() => _stil = v.first),
            ),
          const SizedBox(height: 16),
          TextField(controller: _alat, enabled: !salje, decoration: const InputDecoration(labelText: 'Alat')),
          const SizedBox(height: 12),
          TextField(
            controller: _prompt,
            enabled: !salje,
            minLines: 3,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Prompt kako je slika nastala', alignLabelWithHint: true),
          ),
          if (_greska != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_greska!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 16),
          if (salje) LinearProgressIndicator(value: _napredak) else FilledButton(onPressed: spremno ? _posalji : null, child: const Text('Učitaj kao kandidata')),
        ],
      ),
    );
  }
}
