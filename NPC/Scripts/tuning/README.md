# Character tuning

Runtime values are defined on [`CharacterTuningProfile`](character_tuning_profile.gd) and pushed into gameplay via [`PlayerTuningApplier`](player_tuning_applier.gd). The in-game overlay is an autoload (`CharacterTunerOverlay` in **Project → Project Settings → Autoload**) and calls [`TuningRegistry.apply_for_id`](tuning_registry.gd) for `&"player"`. Toggle: input action `character_tuner_toggle` (default **F3** and **F10**).

**Adding NPCs or enemies later:** give each archetype a `CharacterTuningProfile` resource (or build one in code). In `_ready`, call `TuningRegistry.register(&"your_id", your_node._apply_tuning_profile)` where `_apply_tuning_profile(p: CharacterTuningProfile)` copies fields from `p` into that actor’s movement/combat/camera nodes (same pattern as `PlayerTuningApplier`). Extend the overlay with a target dropdown that calls `apply_for_id` for the selected id. Call `TuningRegistry.unregister` when the actor leaves the tree if ids can be reused.
