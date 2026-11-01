// ignore_for_file: avoid_print
// Mirrors scratch cmp.c so output can be diffed against cubiomes.
import 'package:fixnum/fixnum.dart';
import 'package:seedscout/finder/finder.dart';

void main() {
  final seeds = [Int64(12345), Int64.parseInt('-4172144997902289642'), Int64(99162322)];
  const names = ['village','outpost','desert_pyramid','jungle_temple','swamp_hut','igloo','monument','mansion','shipwreck','ocean_ruin','ruined_portal','ancient_city','trail_ruins','trial_chambers','bastion','end_city','fortress'];
  final out = <String>[];
  for (var si = 0; si < 3; si++) {
    for (var vi = 0; vi < 6; vi++) {
      final f = SeedFinder(seeds[si], McVersion.values[vi]);
      for (final n in names) {
        final feat = features.firstWhere((e) => e.id == n);
        if (!McVersion.values[vi].atLeast(feat.since)) continue;
        if (n == 'fortress' && vi > 0) continue;
        for (var rx = -6; rx <= 6; rx++) {
          for (var rz = -6; rz <= 6; rz++) {
            final c = f.attemptInRegion(feat, rx, rz, villageExclusion: false);
            out.add(c == null ? '$si $vi $n $rx $rz -' : '$si $vi $n $rx $rz ${c.$1} ${c.$2}');
          }
        }
      }
    }
    final f = SeedFinder(seeds[si], McVersion.v1_20);
    final slime = features.firstWhere((e) => e.id == 'slime_chunk');
    final tre = features.firstWhere((e) => e.id == 'buried_treasure');
    for (final h in f.find(slime, 8, 8, limit: 100000)) {
      final cx = (h.x - 8) ~/ 16, cz = (h.z - 8) ~/ 16;
      if (cx.abs() <= 40 && cz.abs() <= 40) out.add('slime $si ${(h.x - 8) >> 4} ${(h.z - 8) >> 4}');
    }
    for (final h in f.find(tre, 9, 9, limit: 100000)) {
      if (((h.x - 9) >> 4).abs() <= 40 && ((h.z - 9) >> 4).abs() <= 40) out.add('treasure $si ${h.x} ${h.z}');
    }
    final sh = features.firstWhere((e) => e.id == 'stronghold');
    for (final h in f.find(sh, 0, 0, limit: 200)) {
      out.add('sh $si ${h.x} ${h.z}');
    }
  }
  out.forEach(print);
}
