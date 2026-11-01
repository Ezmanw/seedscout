// ignore_for_file: avoid_print
import 'package:fixnum/fixnum.dart';
import 'package:seedscout/finder/java_random.dart';

List<String> dump() {
  final out = <String>[];
  out.add('hash ${parseSeed("hello")} ${parseSeed("SeedScout!")} ${parseSeed("99999999999999999999")}');
  for (final s in [Int64(12345), Int64.parseInt('-4172144997902289642'), Int64.MAX_VALUE]) {
    final r = JavaRandom(s);
    out.add('r ${r.nextInt(10)} ${r.nextInt(26)} ${r.nextInt(64)} ${r.nextInt(1000000007)} ${r.nextLong()} ${r.nextDouble()} ${r.nextFloat()}');
    r.setLargeFeatureWithSalt(s, -3, 5, 10387312);
    out.add('salt ${r.nextInt(26)} ${r.nextInt(26)}');
    r.setLargeFeatureSeed(s, -1234567, 98765);
    out.add('large ${r.nextInt(5)} ${r.nextLong()}');
    for (final c in [[0,0],[-1,-1],[100000,-250000],[46341,46341]]) {
      final x = Int64(c[0]), z = Int64(c[1]);
      final ss = (s + Int64((x*x*0x4c1906).toInt32().toInt()) + Int64((x*0x5ac0db).toInt32().toInt()) + Int64((z*z).toInt32().toInt())*0x4307a7 + Int64((z*0x5f24f).toInt32().toInt())) ^ 0x3ad8025f;
      out.add('slime ${JavaRandom(ss).nextInt(10)}');
    }
  }
  return out;
}
void main() { dump().forEach(print); }
