# Manual release runbook

The first `0.1.0` release is manual. Running validation does not authorize a
commit, tag, push, publication, publisher transfer, or GitHub release.

1. Confirm the package name is still available and all `homepage`,
   `repository`, and `issue_tracker` links use HTTPS and resolve correctly.
2. From a clean, reviewed release commit, run the workflow-equivalent checks:
   format, analyzer, package and example tests, coverage, dartdoc, lower
   bounds, Pana, all six example platform builds on Flutter 3.32 and the latest
   stable Flutter, outdated dependencies, and publish dry-run.
3. Review the dry-run archive contents. Add `.pubignore` only if the archive
   includes files that should not ship. Do not commit `pubspec.lock` for this
   library package.
4. Obtain explicit approval, then run `dart pub publish` manually from the
   exact reviewed release commit. Never substitute `--force` for a failed
   validation.
5. After pub.dev confirms 0.1.0, transfer the package to the verified publisher
   `ntfnd404.dev` and verify publisher ownership on the package page.
6. Only with separate approval, create annotated tag `v0.1.0` on the published
   commit and push that tag. Do not move or recreate existing tag `v0.0.1`.
7. Create any GitHub Release only with separate approval.

OIDC publishing is intentionally deferred to a later change after the first
manual release establishes the package and verified publisher.
