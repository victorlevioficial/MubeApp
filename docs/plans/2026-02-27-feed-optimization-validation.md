# Feed Optimization Validation Playbook (v5)

## Goal
Validate phases 1-3 end-to-end with objective metrics and low rollback risk.

## Commits to compare
- Baseline (before optimization): `a36beb5`
- Optimized (phase 1+2+3): `822bb3d`

## Scope
- Home initial load behavior
- Horizontal and vertical list smoothness
- Featured carousel stability
- Refresh and navigation regressions

## Prerequisites
1. At least 2 Android devices:
   - 1 low/mid device (where issues happen)
   - 1 newer device (control)
2. Same network for both runs.
3. Run in `--profile` mode (not debug).

## Automated gate (must pass first)
Run on optimized branch:

```powershell
flutter analyze lib/src/features/feed/
flutter test test/unit/features/feed/ test/widget/features/feed/
```

Expected: no analyzer issues in feed + all feed unit/widget tests passing.

## Manual profiling protocol
Run the exact same scenario on both commits.

### A) Baseline run
```powershell
git checkout a36beb5
flutter pub get
flutter run --profile -d <device-id>
```

### B) Optimized run
```powershell
git checkout perf/feed-phase1
flutter pull
flutter run --profile -d <device-id>
```

### Scenario (repeat 3 times per build)
1. Open app and land on Home.
2. Measure time from first skeleton paint to real content visible.
3. Scroll vertical feed for 45s (normal + fast flicks).
4. Scroll each horizontal section left/right for 20s.
5. Wait on featured carousel for 60s (auto-scroll check).
6. Trigger pull-to-refresh.
7. Tap 3 cards and return back.

## Metrics to collect
Use Flutter DevTools Performance + Memory tabs.

| Metric | Baseline | Optimized | Target |
|---|---:|---:|---:|
| Avg build frame time (ms) |  |  | <= 8 ms |
| Avg raster frame time (ms) |  |  | <= 8 ms |
| Janky frames (%) |  |  | <= 3% |
| Skeleton -> content (ms) |  |  | drop vs baseline |
| Memory delta after 3 min (MB) |  |  | <= +30 MB |

Notes:
- Primary acceptance is relative improvement vs baseline.
- If target is not met but baseline improved significantly, mark as "partial pass" and capture context.

## Stability checks
- No `RangeError` in featured carousel after long auto-scroll.
- No freeze during pull-to-refresh.
- No missing sections after load.
- No like counter desync after toggles.

Optional log capture during run:
```powershell
adb logcat | findstr /i "E/flutter Exception RangeError"
```

## Pass/fail criteria
Pass if all are true:
1. Automated gate passes.
2. No crashes/exceptions in scenario.
3. Optimized build shows lower jank and faster perceived first content than baseline.
4. Memory growth stays controlled in 2-3 min session.

## Rollback policy
If a severe regression appears:
1. Stop rollout.
2. `git checkout a36beb5` (safe baseline).
3. Open issue with exact metric delta + reproduction steps.

## Final report template
```text
Device: <model / android version>
Build compared: a36beb5 vs 822bb3d

Automated gate:
- analyze: PASS/FAIL
- tests: PASS/FAIL

Metrics:
- build ms: <x> -> <y>
- raster ms: <x> -> <y>
- jank %: <x> -> <y>
- skeleton->content ms: <x> -> <y>
- memory delta MB: <x> -> <y>

Behavior:
- carousel stability: PASS/FAIL
- refresh: PASS/FAIL
- navigation: PASS/FAIL

Decision:
- GO / NO-GO
```
