import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'finder/finder.dart';
import 'finder/java_random.dart';

void main() => runApp(const SeedScoutApp());

class SeedScoutApp extends StatelessWidget {
  const SeedScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorSchemeSeed: const Color(0xFF3E8E41),
          brightness: b,
          useMaterial3: true,
        );
    return MaterialApp(
      title: 'SeedScout',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _Result {
  _Result(this.feature, this.version, this.px, this.pz, this.hits);
  final Feature feature;
  final McVersion version;
  final int px, pz;
  final List<Hit> hits;
}

class _HomePageState extends State<HomePage> {
  final _seed = TextEditingController();
  final _x = TextEditingController(text: '0');
  final _z = TextEditingController(text: '0');
  McVersion _version = McVersion.v1_21;
  Feature _feature = features.first;
  _Result? _result;
  String? _error;
  bool _busy = false;

  List<Feature> get _available =>
      features.where((f) => _version.atLeast(f.since)).toList();

  Future<void> _find() async {
    final seed = parseSeed(_seed.text);
    final x = int.tryParse(_x.text.trim());
    final z = int.tryParse(_z.text.trim());
    if (seed == null || x == null || z == null) {
      setState(() => _error = seed == null
          ? 'Enter a world seed (numbers or text).'
          : 'X and Z must be whole numbers.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    // Let the spinner paint before the (synchronous) search runs.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    // Nether coordinates are an eighth of the overworld's.
    final nether = _feature.dim == Dimension.nether;
    final px = nether ? (x / 8).floor() : x;
    final pz = nether ? (z / 8).floor() : z;
    final hits = SeedFinder(seed, _version).find(_feature, px, pz);
    setState(() {
      _busy = false;
      _result = _Result(_feature, _version, px, pz, hits);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = _FormCard(state: this);
    final results = _ResultsView(result: _result, busy: _busy);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SeedScout'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('Minecraft Java seed finder'),
          ),
        ],
      ),
      body: SelectionArea(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 360,
                    child: ListView(
                        padding: const EdgeInsets.all(16), children: [form]),
                  ),
                  Expanded(
                    child: ListView(
                        padding: const EdgeInsets.all(16), children: [results]),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [form, const SizedBox(height: 16), results],
              ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.state});
  final _HomePageState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final available = s._available;
    void update(VoidCallback fn) {
      // ignore: invalid_use_of_protected_member
      s.setState(fn);
    }

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: s._seed,
              decoration: const InputDecoration(
                labelText: 'World seed',
                hintText: 'e.g. -4172144997902289642',
                prefixIcon: Icon(Icons.grass),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => s._find(),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _coordField(s._x, 'Player X', s)),
              const SizedBox(width: 12),
              Expanded(child: _coordField(s._z, 'Player Z', s)),
            ]),
            const SizedBox(height: 4),
            Text('Use your overworld F3 coordinates.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            DropdownMenu<McVersion>(
              expandedInsets: EdgeInsets.zero,
              label: const Text('Game version (Java)'),
              leadingIcon: const Icon(Icons.history),
              initialSelection: s._version,
              dropdownMenuEntries: [
                for (final v in McVersion.values.reversed)
                  DropdownMenuEntry(value: v, label: v.label),
              ],
              onSelected: (v) => update(() {
                s._version = v!;
                if (!v.atLeast(s._feature.since)) s._feature = features.first;
              }),
            ),
            const SizedBox(height: 12),
            DropdownMenu<Feature>(
              key: ValueKey(s._version),
              expandedInsets: EdgeInsets.zero,
              label: const Text('Find'),
              leadingIcon: const Icon(Icons.search),
              initialSelection: s._feature,
              menuHeight: 420,
              enableFilter: true,
              requestFocusOnTap: true,
              dropdownMenuEntries: [
                for (final f in available)
                  DropdownMenuEntry(
                    value: f,
                    label: f.name,
                    leadingIcon: Icon(_iconFor(f)),
                    trailingIcon: f.dim == Dimension.overworld
                        ? null
                        : Text(f.dim == Dimension.nether ? 'Nether' : 'End'),
                  ),
              ],
              onSelected: (f) => update(() => s._feature = f!),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: s._busy ? null : s._find,
              icon: const Icon(Icons.travel_explore),
              label: const Text('Find nearest'),
            ),
            if (s._error != null) ...[
              const SizedBox(height: 12),
              Text(s._error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _coordField(TextEditingController c, String label, _HomePageState s) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onSubmitted: (_) => s._find(),
    );
  }
}

IconData _iconFor(Feature f) => switch (f.kind) {
      Kind.ore => Icons.diamond_outlined,
      Kind.slime => Icons.bubble_chart_outlined,
      Kind.treasure => Icons.savings_outlined,
      Kind.stronghold => Icons.visibility_outlined,
      Kind.structure => switch (f.dim) {
          Dimension.nether => Icons.local_fire_department_outlined,
          Dimension.end => Icons.location_city_outlined,
          Dimension.overworld => Icons.home_work_outlined,
        },
    };

String _compass(int dx, int dz) {
  if (dx == 0 && dz == 0) return 'here';
  // Minecraft: -Z is north, +X is east.
  const names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final deg = (math.atan2(dx, -dz) * 180 / math.pi + 360) % 360;
  return names[((deg + 22.5) ~/ 45) % 8];
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.result, required this.busy});
  final _Result? result;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (busy) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final r = result;
    if (r == null) {
      return Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Icon(Icons.map_outlined,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('Enter a seed and your position, pick what to find.',
                style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Structures use the game\'s own placement maths. Biomes are not '
              'simulated, so most results are candidates.',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }
    if (r.feature.kind == Kind.ore) return _OreCard(result: r);

    final dimName = switch (r.feature.dim) {
      Dimension.nether => ' (Nether coordinates)',
      Dimension.end => ' (End coordinates)',
      Dimension.overworld => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nearest ${r.feature.name.toLowerCase()}s$dimName',
            style: text.headlineSmall),
        if (r.feature.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(r.feature.note!, style: text.bodyMedium),
          ),
        if (r.feature.kind == Kind.stronghold &&
            !r.version.atLeast(McVersion.v1_19_3))
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Before 1.19.3 only the first stronghold can be '
                'computed without biome generation.'),
          ),
        const SizedBox(height: 12),
        if (r.hits.isEmpty)
          const Card.outlined(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nothing found in range.'),
            ),
          )
        else ...[
          Card.outlined(
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 1.6,
              child: CustomPaint(
                painter: _MapPainter(r, Theme.of(context).colorScheme),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card.outlined(
            child: Column(children: [
              for (final (i, h) in r.hits.indexed)
                ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text('X ${h.x}   Z ${h.z}'),
                  subtitle: Text('${h.dist.round()} blocks '
                      '${_compass(h.x - r.px, h.z - r.pz)}'),
                  trailing: IconButton(
                    tooltip: 'Copy /tp command',
                    icon: const Icon(Icons.content_copy),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: '/tp @s ${h.x} ~ ${h.z}'));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Copied /tp @s ${h.x} ~ ${h.z}')));
                    },
                  ),
                ),
            ]),
          ),
        ],
      ],
    );
  }
}

class _OreCard extends StatelessWidget {
  const _OreCard({required this.result});
  final _Result result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final info = oreInfo(r.feature.id, r.version)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final nether = r.feature.dim == Dimension.nether;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${r.feature.name} in ${r.version.label}',
            style: text.headlineSmall),
        const SizedBox(height: 12),
        Card.filled(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Y level', style: text.labelLarge),
                Text('Y ${info.bestY}', style: text.displayMedium),
                Text('Generates between Y ${info.minY} and Y ${info.maxY}. '
                    '${info.tip}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dig plan from your position', style: text.titleMedium),
                const SizedBox(height: 8),
                Text('1. ${nether ? 'In the Nether, at' : 'At'} '
                    'X ${r.px}, Z ${r.pz}, staircase down to Y ${info.bestY}.'),
                const Text('2. Strip-mine a 1×2 tunnel; branch every 3 blocks '
                    'to see every ore face.'),
                const Text('3. Check caves and ravines that cross that level '
                    'first — exposed ore is free.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: scheme.secondary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Exact ore coordinates depend on full terrain, cave and '
                  'biome generation, which a web page can\'t reproduce '
                  'faithfully. Rather than guessing blocks, SeedScout gives '
                  'the level where the game places this ore most often.',
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.r, this.scheme);
  final _Result r;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxDist = r.hits.map((h) => h.dist).fold(64.0, math.max);
    final scale = (math.min(size.width, size.height) / 2 - 24) / maxDist;

    // Range rings at round block distances.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = scheme.outlineVariant;
    final step = _niceStep(maxDist / 3);
    for (var d = step; d <= maxDist * 1.5; d += step) {
      canvas.drawCircle(c, d * scale, ring);
      _label(canvas, '${d.round()}', c + Offset(d * scale + 2, 2),
          scheme.outline, 10);
    }
    _label(canvas, 'N', Offset(c.dx - 4, 4), scheme.outline, 12);

    for (final (i, h) in r.hits.indexed) {
      final p = c + Offset((h.x - r.px) * scale, (h.z - r.pz) * scale);
      canvas.drawCircle(p, 11, Paint()..color = scheme.primary);
      _label(canvas, '${i + 1}', p - const Offset(4, 7), scheme.onPrimary, 11);
    }

    // Player arrow.
    final path = Path()
      ..moveTo(c.dx, c.dy - 9)
      ..lineTo(c.dx + 7, c.dy + 7)
      ..lineTo(c.dx - 7, c.dy + 7)
      ..close();
    canvas.drawPath(path, Paint()..color = scheme.tertiary);
  }

  double _niceStep(double raw) {
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 5, 10]) {
      if (raw <= m * mag) return m * mag;
    }
    return 10 * mag;
  }

  void _label(Canvas canvas, String s, Offset at, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color, fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.r != r || old.scheme != scheme;
}
