# SeedScout — implementation brief

**Goal:** Material 3 Flutter Web app. Enter seed, player X/Z and Java version → see the
nearest structures/features listed and drawn on a map around you.

**Scope (Java Edition 1.16 → 1.21+, client-side only, no backend)**
- **Exact placement** (same RNG as the game): villages, outposts, temples, igloos,
  swamp huts, monuments, mansions, shipwrecks, ocean ruins, ruined portals, buried
  treasure, ancient cities, trail ruins, trial chambers, fortresses/bastions, end
  cities, slime chunks.
- **Approximate:** strongholds (ring algorithm; game snaps up to ~112 blocks to a
  biome; only stronghold #1 is computable before 1.19.3).
- **Not computable without full terrain/biome gen:** ore & single-block positions.
  The app shows each ore's best Y-level for the version and a dig plan from the
  player instead of fabricating coordinates.
- Biomes are not simulated, so structure hits are *candidates* — labelled as such.

**Tech**
- `fixnum` `Int64` for Java `Random` (48-bit LCG) — Dart web ints are 53-bit doubles.
- Seed: numeric → long, else Java `String.hashCode`.
- Region search: `RandomSpreadStructurePlacement` (spacing, separation, salt,
  linear/triangular), outpost frequency + village exclusion, nether set weighting.
- UI: seed/X/Z/version form, feature dropdown, nearest-10 list (coords, distance,
  copy `/tp`), `CustomPainter` map with zoom.

**Ship:** repo `Ezmanw/seedscout`, built with `--no-web-resources-cdn
--base-href /seedscout/`, served from GitHub Pages (`gh-pages` branch).
