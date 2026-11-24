# M6 review 14:45 — candidate corrections, CI required
Source: https://github.com/pitinga/game-mobile-builds/blob/main/review/review-retro-arcade-m6-20261124-1445.md
| ID | Candidate change | Evidence still required |
|---|---|---|
| M6-001 | Raised barriers, optional cut-or-fly routes, elevated cells, lower starting energy after level 2, stronger drain, paid pulse and moving enemies | Full campaign no-life-loss gate, playtest, resource/route solver |
| M6-002 | 9 gaps 144u exceed jump range, moving platform widened, varied artifact positions, overhead hazard in selected later rooms | Full campaign and naive gates, bridge reachability, playtest |
| M6-003 | Exact life gates and naive gates, 20 unique tilemaps with dimensions/start/rescue and battery checks, room descriptor checks, replay horizon 120s | CI, not exhaustive route solver; replay may terminate early |
| M6-004 | Distinct X/!/dot, clear wall outline, darkness drawn behind gameplay elements | Visual pixel review |
| M6-005 | Timed ladder both ways, checkpoint uses actual x=80, tests | CI |
| M6-006 | Ladder by direction only, automatic stationary rescue | Physical control QA remains |
| M6-007 | Live capture state assertions, labeled visual fixtures warning/active/dark, ladder/bridge/victory | Persist after green CI; fixture not live behavior proof |
| M6-008 | Move level 20 vapor away from rescue, hazard clearance regression | CI |
First attempt e66b5a54: CI 45454102006 failed G06 live campaign 0/3 at level 20; G08 3/3. No merge until corrected and all gates pass. M7 not started.