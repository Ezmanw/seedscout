import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';

import 'java_random.dart';

/// Java Edition version groups whose structure generation differs.
enum McVersion {
  v1_16('1.16 – 1.17'),
  v1_18('1.18.x'),
  v1_19('1.19 – 1.19.2'),
  v1_19_3('1.19.3 – 1.19.4'),
  v1_20('1.20.x'),
  v1_21('1.21+');

  const McVersion(this.label);
  final String label;

  bool atLeast(McVersion o) => index >= o.index;
}

enum Dimension { overworld, nether, end }

enum Kind { structure, stronghold, slime, treasure, ore }

class Placement {
  const Placement(this.spacing, this.separation, this.salt,
      {this.triangular = false});
  final int spacing, separation, salt;
  final bool triangular;
}

class Feature {
  const Feature(this.id, this.name, this.kind,
      {this.dim = Dimension.overworld,
      this.placement,
      this.since = McVersion.v1_16,
      this.note});
  final String id, name;
  final Kind kind;
  final Dimension dim;
  final Placement? placement;
  final McVersion since;
  final String? note;
}

const _biomeNote = 'Candidate spot — spawns only if the biome there allows it.';

/// Placement for [f] in [v]; villages widened their spacing in 1.18.
Placement? placementFor(Feature f, McVersion v) {
  if (f.id == 'village' && !v.atLeast(McVersion.v1_18)) {
    return const Placement(32, 8, 10387312);
  }
  return f.placement;
}

const features = <Feature>[
  Feature('village', 'Village', Kind.structure,
      placement: Placement(34, 8, 10387312), note: _biomeNote),
  Feature('outpost', 'Pillager outpost', Kind.structure,
      placement: Placement(32, 8, 165745296), note: _biomeNote),
  Feature('desert_pyramid', 'Desert pyramid', Kind.structure,
      placement: Placement(32, 8, 14357617), note: _biomeNote),
  Feature('jungle_temple', 'Jungle temple', Kind.structure,
      placement: Placement(32, 8, 14357619), note: _biomeNote),
  Feature('swamp_hut', 'Witch hut', Kind.structure,
      placement: Placement(32, 8, 14357620), note: _biomeNote),
  Feature('igloo', 'Igloo', Kind.structure,
      placement: Placement(32, 8, 14357618), note: _biomeNote),
  Feature('monument', 'Ocean monument', Kind.structure,
      placement: Placement(32, 5, 10387313, triangular: true),
      note: _biomeNote),
  Feature('mansion', 'Woodland mansion', Kind.structure,
      placement: Placement(80, 20, 10387319, triangular: true),
      note: _biomeNote),
  Feature('shipwreck', 'Shipwreck', Kind.structure,
      placement: Placement(24, 4, 165745295), note: _biomeNote),
  Feature('ocean_ruin', 'Ocean ruin', Kind.structure,
      placement: Placement(20, 8, 14357621), note: _biomeNote),
  Feature('ruined_portal', 'Ruined portal', Kind.structure,
      placement: Placement(40, 15, 34222645),
      note: 'Spawns in almost every biome.'),
  Feature('ancient_city', 'Ancient city', Kind.structure,
      placement: Placement(24, 8, 20083232),
      since: McVersion.v1_19,
      note: 'Candidate — only real under a Deep Dark biome (Y≈-51).'),
  Feature('trail_ruins', 'Trail ruins', Kind.structure,
      placement: Placement(34, 8, 83469867),
      since: McVersion.v1_20,
      note: _biomeNote),
  Feature('trial_chambers', 'Trial chambers', Kind.structure,
      placement: Placement(34, 12, 94251327),
      since: McVersion.v1_21,
      note: 'Underground (Y -40 to -20); spawns in almost every biome.'),
  Feature('stronghold', 'Stronghold', Kind.stronghold,
      note: 'Approximate — the game nudges it up to ~112 blocks to a valid '
          'biome. Use eyes of ender for the last stretch.'),
  Feature('buried_treasure', 'Buried treasure', Kind.treasure,
      note: 'Exact chunk; only real on a beach. Dig at the block shown.'),
  Feature('slime_chunk', 'Slime chunk', Kind.slime,
      note: 'Exact. Slimes spawn below Y 40 in these chunks.'),
  Feature('fortress', 'Nether fortress', Kind.structure,
      dim: Dimension.nether,
      placement: Placement(27, 4, 30084232),
      note: 'From 1.18, also appears at a bastion spot in basalt deltas.'),
  Feature('bastion', 'Bastion remnant', Kind.structure,
      dim: Dimension.nether,
      placement: Placement(27, 4, 30084232),
      note: 'Not in basalt deltas.'),
  Feature('end_city', 'End city', Kind.structure,
      dim: Dimension.end,
      placement: Placement(20, 11, 10387313, triangular: true),
      note: 'Candidate — needs an outer island tall enough there.'),
  // Ores: not placeable without full terrain generation (see ores below).
  Feature('diamond', 'Diamond ore', Kind.ore),
  Feature('ancient_debris', 'Ancient debris', Kind.ore, dim: Dimension.nether),
  Feature('iron', 'Iron ore', Kind.ore),
  Feature('gold', 'Gold ore', Kind.ore),
  Feature('redstone', 'Redstone ore', Kind.ore),
  Feature('lapis', 'Lapis lazuli ore', Kind.ore),
  Feature('emerald', 'Emerald ore', Kind.ore),
  Feature('coal', 'Coal ore', Kind.ore),
  Feature('copper', 'Copper ore', Kind.ore),
];

class Hit {
  Hit(this.x, this.z, this.dist, {this.y});
  final int x, z;
  final int? y;
  final double dist;
}

class OreInfo {
  const OreInfo(this.bestY, this.minY, this.maxY, this.tip);
  final int bestY, minY, maxY;
  final String tip;
}

OreInfo? oreInfo(String id, McVersion v) {
  final modern = v.atLeast(McVersion.v1_18);
  switch (id) {
    case 'diamond':
      return modern
          ? const OreInfo(-59, -64, 16, 'Most common at the bottom of the world.')
          : const OreInfo(11, 1, 16, 'Y 11 keeps you above most lava lakes.');
    case 'ancient_debris':
      return const OreInfo(15, 8, 119,
          'Nether only. Bed or TNT mining at Y 15 is fastest.');
    case 'iron':
      return modern
          ? const OreInfo(15, -64, 320, 'Second peak at Y 232 in mountains.')
          : const OreInfo(16, 1, 63, 'Even spread below Y 64.');
    case 'gold':
      return modern
          ? const OreInfo(-16, -64, 32, 'Badlands have extra gold up to Y 256.')
          : const OreInfo(12, 1, 32, 'Badlands have extra gold up to Y 79.');
    case 'redstone':
      return modern
          ? const OreInfo(-59, -64, 15, 'Mine alongside diamonds.')
          : const OreInfo(12, 1, 15, 'Mine alongside diamonds.');
    case 'lapis':
      return modern
          ? const OreInfo(0, -64, 64, 'Buried lapis peaks lower, around Y -1.')
          : const OreInfo(14, 0, 30, 'Peaks around Y 14.');
    case 'emerald':
      return modern
          ? const OreInfo(232, -16, 320, 'Mountain biomes only.')
          : const OreInfo(16, 4, 31, 'Mountain biomes only.');
    case 'coal':
      return modern
          ? const OreInfo(95, 0, 320, 'Usually visible on cliffs and caves.')
          : const OreInfo(45, 0, 127, 'Usually visible on cliffs and caves.');
    case 'copper':
      if (!modern) {
        return const OreInfo(47, 0, 96, 'Added in 1.17; not in 1.16.');
      }
      return const OreInfo(48, -16, 112, 'Dripstone caves have the most.');
  }
  return null;
}

int _floorDiv(int a, int b) => (a / b).floor();

class SeedFinder {
  SeedFinder(this.seed, this.version);
  final Int64 seed;
  final McVersion version;
  final _r = JavaRandom(Int64.ZERO);

  /// The chunk a structure set picks inside region ([rx], [rz]).
  (int, int) _regionChunk(Placement p, int rx, int rz) {
    _r.setLargeFeatureWithSalt(seed, rx, rz, p.salt);
    final range = p.spacing - p.separation;
    int off() => p.triangular
        ? (_r.nextInt(range) + _r.nextInt(range)) ~/ 2
        : _r.nextInt(range);
    final ox = off();
    final oz = off();
    return (rx * p.spacing + ox, rz * p.spacing + oz);
  }

  bool _villageWithin(int cx, int cz, int chunks) {
    final p = placementFor(features.first, version)!;
    for (var rx = _floorDiv(cx - chunks, p.spacing);
        rx <= _floorDiv(cx + chunks, p.spacing);
        rx++) {
      for (var rz = _floorDiv(cz - chunks, p.spacing);
          rz <= _floorDiv(cz + chunks, p.spacing);
          rz++) {
        final (vx, vz) = _regionChunk(p, rx, rz);
        if ((vx - cx).abs() <= chunks && (vz - cz).abs() <= chunks) {
          return true;
        }
      }
    }
    return false;
  }

  /// The chunk [f] attempts in region ([rx], [rz]), or null when the
  /// placement rules (frequency, exclusion, nether weighting) reject it.
  (int, int)? attemptInRegion(Feature f, int rx, int rz,
      {bool villageExclusion = true}) {
    final (cx, cz) = _regionChunk(placementFor(f, version)!, rx, rz);
    switch (f.id) {
      case 'outpost':
        // FrequencyReductionMethod.LEGACY_TYPE_1 at 0.2.
        _r.setSeed(Int64((cx >> 4) ^ ((cz >> 4) << 4)) ^ seed);
        _r.next(32);
        if (_r.nextInt(5) != 0) return null;
        // Exclusion zone: no village start within 10 chunks.
        if (villageExclusion && _villageWithin(cx, cz, 10)) return null;
      case 'fortress':
      case 'bastion':
        // 1.16-1.17 keep rolling the region RNG; 1.18+ reseed per chunk.
        if (version.atLeast(McVersion.v1_18)) {
          _r.setLargeFeatureSeed(seed, cx, cz);
        }
        final bastion = _r.nextInt(5) >= 2;
        if (bastion != (f.id == 'bastion')) return null;
      case 'end_city':
        // The main island and the void around it never get cities.
        final bx = cx * 16, bz = cz * 16;
        if (bx * bx + bz * bz < 1008 * 1008) return null;
    }
    return (cx, cz);
  }

  List<Hit> find(Feature f, int px, int pz, {int limit = 10}) {
    switch (f.kind) {
      case Kind.structure:
        return _structures(f, px, pz, limit);
      case Kind.stronghold:
        return _strongholds(px, pz, limit);
      case Kind.slime:
        return _perChunk(px, pz, 48, limit, (cx, cz) => _isSlime(cx, cz), 8);
      case Kind.treasure:
        return _perChunk(px, pz, 96, limit, (cx, cz) {
          _r.setLargeFeatureWithSalt(seed, cx, cz, 10387320);
          return _r.nextFloat() < 0.01;
        }, 9);
      case Kind.ore:
        return const [];
    }
  }

  List<Hit> _structures(Feature f, int px, int pz, int limit) {
    final p = placementFor(f, version)!;
    final regionBlocks = p.spacing * 16;
    final radius = math.max(2, (12000 / regionBlocks).ceil());
    final prx = _floorDiv(_floorDiv(px, 16), p.spacing);
    final prz = _floorDiv(_floorDiv(pz, 16), p.spacing);
    final hits = <Hit>[];
    for (var rx = prx - radius; rx <= prx + radius; rx++) {
      for (var rz = prz - radius; rz <= prz + radius; rz++) {
        final c = attemptInRegion(f, rx, rz);
        if (c == null) continue;
        final (cx, cz) = c;
        final x = cx * 16 + 8, z = cz * 16 + 8;
        hits.add(Hit(x, z, _dist(px, pz, x, z)));
      }
    }
    hits.sort((a, b) => a.dist.compareTo(b.dist));
    return hits.take(limit).toList();
  }

  List<Hit> _strongholds(int px, int pz, int limit) {
    // ConcentricRingsStructurePlacement: distance 32, spread 3, count 128.
    // Before 1.19.3 the biome search shares this RNG, so only #1 is knowable.
    final exact = version.atLeast(McVersion.v1_19_3);
    final r = JavaRandom(seed);
    var angle = r.nextDouble() * math.pi * 2;
    var ring = 0, inRing = 0, spread = 3;
    const count = 128, distance = 32;
    final hits = <Hit>[];
    for (var i = 0; i < count; i++) {
      final d = (4 * distance + distance * ring * 6) +
          (r.nextDouble() - 0.5) * (distance * 2.5);
      final cx = (math.cos(angle) * d + 0.5).floor();
      final cz = (math.sin(angle) * d + 0.5).floor();
      // The portal-room staircase sits at block (4, 4) of the chunk.
      final x = cx * 16 + 4, z = cz * 16 + 4;
      hits.add(Hit(x, z, _dist(px, pz, x, z)));
      if (!exact) break;
      r.nextLong(); // randomSource.fork()
      angle += math.pi * 2 / spread;
      if (++inRing == spread) {
        ring++;
        inRing = 0;
        spread += 2 * spread ~/ (ring + 1);
        spread = math.min(spread, count - i);
        angle += r.nextDouble() * math.pi * 2;
      }
    }
    hits.sort((a, b) => a.dist.compareTo(b.dist));
    return hits.take(limit).toList();
  }

  bool _isSlime(int cx, int cz) {
    final x = Int64(cx), z = Int64(cz);
    final s = (seed +
            Int64((x * x * 0x4c1906).toInt32().toInt()) +
            Int64((x * 0x5ac0db).toInt32().toInt()) +
            Int64((z * z).toInt32().toInt()) * 0x4307a7 +
            Int64((z * 0x5f24f).toInt32().toInt())) ^
        0x3ad8025f;
    _r.setSeed(s);
    return _r.nextInt(10) == 0;
  }

  List<Hit> _perChunk(int px, int pz, int radius, int limit,
      bool Function(int cx, int cz) test, int offset) {
    final pcx = _floorDiv(px, 16), pcz = _floorDiv(pz, 16);
    final hits = <Hit>[];
    // Spiral outwards by ring so we can stop early once results are certain.
    for (var ring = 0; ring <= radius; ring++) {
      for (var dx = -ring; dx <= ring; dx++) {
        for (var dz = -ring; dz <= ring; dz++) {
          if (dx.abs() != ring && dz.abs() != ring) continue;
          final cx = pcx + dx, cz = pcz + dz;
          if (!test(cx, cz)) continue;
          final x = cx * 16 + offset, z = cz * 16 + offset;
          hits.add(Hit(x, z, _dist(px, pz, x, z)));
        }
      }
      // Anything in a later ring is at least ring*16 blocks away.
      if (hits.length >= limit) {
        hits.sort((a, b) => a.dist.compareTo(b.dist));
        if (hits[limit - 1].dist <= ring * 16) break;
      }
    }
    hits.sort((a, b) => a.dist.compareTo(b.dist));
    return hits.take(limit).toList();
  }

  static double _dist(int ax, int az, int bx, int bz) {
    final dx = (ax - bx).toDouble(), dz = (az - bz).toDouble();
    return math.sqrt(dx * dx + dz * dz);
  }
}
