import 'package:fixnum/fixnum.dart';

/// Bit-exact port of `java.util.Random`. Dart web ints are doubles, so the
/// 48-bit LCG runs on [Int64].
class JavaRandom {
  static final Int64 _mult = Int64(0x5DEECE66D);
  static final Int64 _mask = (Int64.ONE << 48) - 1;

  Int64 _seed = Int64.ZERO;

  JavaRandom(Int64 seed) {
    setSeed(seed);
  }

  void setSeed(Int64 seed) => _seed = (seed ^ _mult) & _mask;

  /// `WorldgenRandom.setLargeFeatureWithSalt`.
  void setLargeFeatureWithSalt(Int64 worldSeed, int x, int z, int salt) {
    setSeed(Int64(x) * Int64(341873128712) +
        Int64(z) * Int64(132897987541) +
        worldSeed +
        Int64(salt));
  }

  /// `WorldgenRandom.setLargeFeatureSeed`.
  void setLargeFeatureSeed(Int64 worldSeed, int x, int z) {
    setSeed(worldSeed);
    final a = nextLong();
    final b = nextLong();
    setSeed((Int64(x) * a) ^ (Int64(z) * b) ^ worldSeed);
  }

  int next(int bits) {
    _seed = (_seed * _mult + 0xB) & _mask;
    return (_seed >> (48 - bits)).toInt32().toInt();
  }

  int nextInt(int bound) {
    if ((bound & -bound) == bound) {
      return ((Int64(bound) * next(31)) >> 31).toInt();
    }
    int bits, val;
    do {
      bits = next(31);
      val = bits % bound;
    } while (bits - val + (bound - 1) > 0x7FFFFFFF); // int32 overflow
    return val;
  }

  Int64 nextLong() => (Int64(next(32)) << 32) + Int64(next(32));

  double nextFloat() => next(24) / (1 << 24);

  double nextDouble() => (next(26) * 134217728.0 + next(27)) / 9007199254740992.0;
}

final _longMin = -(BigInt.one << 63);
final _longMax = (BigInt.one << 63) - BigInt.one;

/// Numeric seeds parse as a long; anything else uses Java `String.hashCode`,
/// exactly like the world-creation screen.
Int64? parseSeed(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;
  if (RegExp(r'^-?\d+$').hasMatch(s)) {
    final big = BigInt.parse(s);
    // Out of long range: the game treats it as text.
    if (big >= _longMin && big <= _longMax) return Int64.parseInt(s);
  }
  var h = 0;
  for (final c in s.codeUnits) {
    h = (31 * h + c).toSigned(32);
  }
  return Int64(h);
}
