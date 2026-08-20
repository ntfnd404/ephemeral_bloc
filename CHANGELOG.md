## 0.1.0

* **Breaking:** action callbacks now receive `(context, action)` without a
  state snapshot.
* **Breaking:** `EphemeralBlocObserver.onAction` now receives the action
  directly; `EphemeralBlocChange` was removed.
* Constrain action types to non-nullable `Object` values.
* Mark `emitAction` as protected and safely ignore emissions after closing
  starts.
* Capture the action observer when the BLoC or Cubit is created.
* Correct action-stream shutdown and provider-replacement lifecycle behavior.
* Add complete API documentation, runnable example, release checks, and
  expanded lifecycle/widget tests.

## 0.0.1

* Initial release.
* `EphemeralBlocMixin` — adds a fire-and-forget one-shot action stream to any `BlocBase`, separate from state.
* `EphemeralBlocListener` — listens to one-shot actions, compatible with `MultiBlocListener`.
* `EphemeralBlocConsumer` — combines `EphemeralBlocListener`, an optional `BlocListener`, and `BlocBuilder` in one widget.
* `EphemeralBlocObserver` — mixin for `BlocObserver` to observe actions emitted across all BLoCs.
* `EphemeralBlocChange` — snapshot of an action transition (`previous`/`current`).
