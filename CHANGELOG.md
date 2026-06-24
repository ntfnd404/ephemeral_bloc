## 0.0.1

* Initial release.
* `EphemeralBlocMixin` — adds a fire-and-forget one-shot action stream to any `BlocBase`, separate from state.
* `EphemeralBlocListener` — listens to one-shot actions, compatible with `MultiBlocListener`.
* `EphemeralBlocConsumer` — combines `EphemeralBlocListener`, an optional `BlocListener`, and `BlocBuilder` in one widget.
* `EphemeralBlocObserver` — mixin for `BlocObserver` to observe actions emitted across all BLoCs.
* `EphemeralBlocChange` — snapshot of an action transition (`previous`/`current`).
