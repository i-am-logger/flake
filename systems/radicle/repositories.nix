# The fleet's repositories, named ONCE.
#
# A machine definition should not know which repositories exist. A seed is a
# seed whatever it happens to hold, and a builder is a builder; what they carry
# is fleet DATA. Naming repositories inside ./seed.nix and ./builder.nix put the
# same two rids in two machine files, which is both duplication and a category
# error -- the same one that had radicle-yoga-x64-builder living inside
# systems/yoga/.
#
# WHO USES THIS, AND WHO DOES NOT:
#
#   A SEED does not. It runs `defaultSeedingPolicy = "allow"` with scope "all",
#   which means it takes whatever is announced -- so enumerating repositories
#   there says nothing the policy does not already say, and says it wrongly:
#   yoga's seed listed two while actually holding three.
#
#   A BUILDER does. Every repository it seeds is one whose CI recipe it will
#   execute, so that list must be a decision rather than a side effect of what
#   happens to be announced. `ci = false` keeps a repository off builders while
#   leaving it here as a record of what the fleet has.
{
  secure-sweep-mobile = {
    rid = "rad:z2WxYCuLx8F8r2bPLPNjjboGM7qPU";
    description = "Offline on-device Android counter-surveillance";
    ci = true;
  };

  radicle-ci-smoke = {
    rid = "rad:z4KpNmJDpSD4xYHcsASaWa9y3AKTd";
    description = "Smoke test: proves the containerised builder runs CI end to end";
    ci = true;
  };

  # A third repository, rad:zfDtFXYCZjVrrJ2gbFUPZVAK1XzC, reached the seed
  # through the allow policy and was deleted as unwanted. Noted only so its
  # like is recognised rather than investigated next time: a seed running
  # `defaultSeedingPolicy = "allow"` with scope "all" accepts whatever a peer
  # announces, so repositories arrive here without appearing in this file. That
  # is the policy working, and it is the reason a seed does not enumerate
  # repositories at all -- only builders do, because they execute recipes.
}
