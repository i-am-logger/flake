# CI/CD Workflows

## `ci.yml`

Three independent jobs, cheapest first:

| Job | What it does |
|-----|--------------|
| **Lint** | `statix check` + `deadnix --fail` over tracked `.nix` files |
| **Format** | `nix fmt` (nixpkgs-fmt) followed by `git diff --exit-code` |
| **Flake Check** | `nix flake check --no-build`, then an explicit `nix eval` per host |

They do not `needs:` each other. The old pipeline chained six jobs so that a
formatting slip blocked the flake check behind it, which buys nothing when the
jobs run on separate runners anyway.

### Two things worth knowing

**The `secrets` input cannot be fetched by any runner.** It is a path input
pointing at `/home/logger/.secrets`, which exists on yoga and skyspy-dev and
nowhere else. Every nix command overrides it with an empty directory. That is
sound because nothing CI evaluates reads a secret's *content* — sops decryption
happens at activation.

**Systems are evaluated, not built.** `--no-build` realises no system closure.
Building yoga's and skyspy-dev's toplevels is what the self-hosted runners were
meant for, and the closures do not fit a hosted runner's 14 GB. Evaluation is
what catches a broken module, which is what changes in this repo.

`darwinConfigurations` is a known-but-unchecked flake attribute, so
`nix flake check` never looks at it — the Mac is evaluated by name in the last
step, or it would be the one host CI ignores.

## `release.yml` / `release-pr.yml`

release-please. Both previously targeted `runs-on: flake`.

## History

Everything above replaced a pipeline that **had never run**. No self-hosted
runner was ever registered against this repository, so every workflow queued
until GitHub's 48-hour limit and was cancelled — the record goes back to at
least 2026-06. Consequences worth naming, because they were invisible:

- The format job ran `alejandra --check`, a different formatter from the repo's
  `nixpkgs-fmt`. The two disagree on nearly every file.
- release-please had never opened a release PR for this repository.
- A `summary` job re-implemented, in shell, what GitHub's own required status
  checks already report.
- `test-runner.yml` existed only to probe a `host-yoga-repo-flake` runner that
  does not exist. Deleted.

To go back to self-hosted, register a runner and change `runs-on:` — the rest of
these workflows do not assume a hosted one, apart from the store cache.
