# TODO

- [x] https://github.com/nix-community/impermanence integrate this to yoga system
- [x] secure boot
- [x] login, github yubikey
- [x] fix: ubikey requires both touch and password, i rather not require the password)
- [x] secrets 
- [ ] custom nixos installer - include warp, gnmoe, btop, helix, fastfetch, latestkernel, git, clone of i-am-logger/flake
- [ ] restructure the flake directories 
- [x] bash
- [ ] flake scripts


aliases

tree -d -I "result|target|.direnv|.devenvi|node_modules"

## Claw Recruiter — NixOS Infrastructure (Track 1)

- [x] Step 1: Ollama module — GPU auto-detect (CUDA/ROCm/CPU), Qwen 2.5 14B
- [x] Step 2: OpenClaw module — buildNpmPackage, systemd service, shared client config
- [ ] Step 3: Signal CLI module — signal-cli service, phone registration
- [ ] Step 4: RxResume — OCI containers (app + postgres + minio + chrome)
- [ ] Step 5: MCP servers — rxresume-mcp systemd service
- [ ] Step 6: Enable everything in skyspy-dev.nix, verify end-to-end

### Verified

- [x] Ollama running with CUDA on RTX 4080 (12GB)
- [x] Qwen 2.5 14B loaded, ~1s per JSON scoring call
- [x] OpenClaw gateway running on port 18789
- [x] CLI: `openclaw agent --session-id test --message "hello"` works via Ollama

## Claw Recruiter — Plugin (Track 2: ~/Code/github/logger/claw-recruiter/)

- [ ] Phase 1: Skeleton + DB + Config — devenv.nix, package.json, SQLite schema, types
- [ ] Phase 2: Profile + LLM client — resume upload, Ollama client, JSON parser
- [ ] Phase 3: Scoring engine — 3-category rubric, robust JSON parsing
- [ ] Phase 4: Sources + Pipeline — jobspy, HN, Wellfound scrapers + orchestration
- [ ] Phase 5: MCP integration — RxResume MCP for prep, Gmail MCP for email
- [ ] Phase 6: Background service + Signal notifications
- [ ] Phase 7: Tracking + Stats — application tracking, funnel analytics
- [ ] Phase 8: Learning loop — outcome feedback, scoring calibration
- [ ] Phase 9: Communication — email drafting, inbox monitoring
- [ ] Phase 10: Advise — interview prep, company research, negotiation

## Ricing

- [ ] Hypland layout - mission control - https://github.com/dawsers/hyprscroller
    - hypr-mission 
- [ ] vogix16 - https://github.com/i-am-logger/vogix16
