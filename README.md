# SeedScout

Material 3 Flutter Web app: enter a Minecraft **Java** seed, your X/Z and version
(1.16 → 1.21+) and see the nearest structures on a map.

**Live:** https://ezmanw.github.io/seedscout/

- Exact placement for villages, outposts, temples, monuments, mansions, shipwrecks,
  ocean ruins, ruined portals, buried treasure, ancient cities, trail ruins, trial
  chambers, fortresses, bastions, end cities and slime chunks.
- Strongholds: ring positions (the game nudges each up to ~112 blocks to a biome).
- Ores: best Y-level and range per version. Exact ore blocks need full terrain
  generation, so the app doesn't guess them.
- Biomes aren't simulated, so structure hits are candidates.

Verified bit-for-bit against [cubiomes](https://github.com/Cubitect/cubiomes)
(`tool/cubiomes_dump.dart`) and real `java.util.Random` (`tool/rng_dump.dart`).
See [BRIEF.md](BRIEF.md).

```bash
flutter test
flutter build web --release --no-web-resources-cdn --base-href /seedscout/
```
