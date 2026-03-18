# Plan: Personal AI Recruiter — Full Stack

## Context

Build a personal AI recruiter that runs 24/7 on NixOS. Upload your resume, it finds jobs, scores them, tailors resumes, tracks applications, and notifies you on Signal. Fully local — no cloud APIs.

Two tracks of work:
1. **Infrastructure** (`/etc/nixos/`) — NixOS modules for Ollama (CUDA), OpenClaw, Signal CLI, RxResume, MCP servers
2. **Recruiter plugin** (`~/Code/github/logger/claw-recruiter/`) — The actual recruiter logic as an OpenClaw extension

## Current State (skyspy-dev)

- **GPU:** NVIDIA RTX 4080 Mobile 12GB — CUDA fully configured (`/etc/nixos/hosts/common/nvidia.nix`)
- **Ollama:** Module exists at `/etc/nixos/hosts/common/ollama.nix` but is **disabled** (`# common/ollama.nix` in skyspy-dev.nix) and configured for **ROCm (AMD)** — needs CUDA version
- **OpenClaw:** Not installed, not configured
- **Signal CLI:** Not installed
- **Docker:** Available (`common/docker.nix` imported)
- **NixOS:** Flake-based, impermanence, sops-nix for secrets, home-manager
- **Host config:** `/etc/nixos/hosts/skyspy-dev.nix`

## Track 1: NixOS Infrastructure

### Step 1: Refactor Ollama module (GPU-agnostic)

Rewrite `/etc/nixos/hosts/common/ollama.nix` to be parameterized instead of hardcoded to ROCm.

**New pattern:** Auto-detect GPU from existing NixOS hardware config. No per-host `acceleration` setting needed.

Detection logic:
- `config.hardware.nvidia.modesetting.enable == true` → CUDA (skyspy-dev has this in `nvidia.nix`)
- `builtins.elem "amdgpu" config.services.xserver.videoDrivers` → ROCm
- Neither → CPU only

```nix
# /etc/nixos/hosts/common/ollama.nix — rewritten
{ pkgs, lib, config, ... }:
let
  hasNvidia = config.hardware.nvidia.modesetting.enable or false;
  hasAmd = builtins.elem "amdgpu" (config.services.xserver.videoDrivers or []);
  acceleration = if hasNvidia then "cuda" else if hasAmd then "rocm" else false;
  isRocm = acceleration == "rocm";
  isCuda = acceleration == "cuda";
in {
  options.local.ollama.models = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Models to auto-pull on start";
  };

  config = {
    services.ollama = {
      enable = true;
      package = if isRocm then pkgs.ollama-rocm else pkgs.ollama;
      inherit acceleration;
      loadModels = config.local.ollama.models;
      user = "ollama";
      group = "ollama";
      home = "/var/lib/ollama";
      models = "/var/lib/ollama/models";
    };

    # ROCm packages only when AMD
    environment.systemPackages = lib.mkIf isRocm (with pkgs; [
      rocmPackages.rocm-runtime
      rocmPackages.rocm-device-libs
      rocmPackages.rocm-smi
    ]);

    # Shared memory optimizations + ROCm-specific env vars
    environment.variables = lib.mkMerge [
      {
        OLLAMA_HOST = "127.0.0.1:11434";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_FLASH_ATTENTION = "true";
      }
      (lib.mkIf isRocm {
        ROC_ENABLE_PRE_VEGA = "1";
        HSA_OVERRIDE_GFX_VERSION = "11.0.2";
      })
    ];

    systemd.services.ollama.environment = lib.mkIf isRocm {
      HSA_OVERRIDE_GFX_VERSION = "11.0.2";
      ROC_ENABLE_PRE_VEGA = "1";
    };

    # Shared: user, group, tmpfiles
    users.users.ollama = { isSystemUser = true; group = "ollama"; home = "/var/lib/ollama"; extraGroups = [ "render" "video" ]; };
    users.groups.ollama = {};
    systemd.tmpfiles.rules = [ "d /var/lib/ollama 0755 ollama ollama -" "d /var/lib/ollama/models 0755 ollama ollama -" ];
    systemd.services.ollama.serviceConfig.DynamicUser = lib.mkForce false;
  };
}
```

**Per-host: only set models (GPU auto-detected)**
```nix
# skyspy-dev.nix — auto-detects CUDA from nvidia.nix
local.ollama.models = [ "qwen2.5:14b" ];

# handlink.nix — auto-detects ROCm from amdgpu videoDriver
local.ollama.models = [ "llama3.2:3b" ];
```

Uncomment `common/ollama.nix` in `skyspy-dev.nix` and set models.

### Step 2: OpenClaw module

Create `/etc/nixos/hosts/common/openclaw.nix`

OpenClaw is a Node.js application. The module needs to:
- Install Node.js 22 + pnpm
- Build OpenClaw from source (or use a Nix derivation wrapping the npm package)
- Run `openclaw gateway` as a systemd service
- Configure Signal as a channel
- Configure Ollama as the LLM provider (`http://localhost:11434`)
- After `ollama.service`

### Step 3: Signal CLI module

Create `/etc/nixos/hosts/common/signal-cli.nix`

- Install `signal-cli` package (available in nixpkgs)
- Run as a systemd service in daemon mode (D-Bus or JSON-RPC)
- OpenClaw connects to it for Signal messaging
- Requires initial registration (phone number + verification)

### Step 4: RxResume (OCI containers)

Create `/etc/nixos/hosts/common/rxresume.nix`

Using `virtualisation.oci-containers` (Docker is already available):
- `rxresume` container (the app)
- `rxresume-postgres` container (database)
- `rxresume-minio` container (file storage)
- `rxresume-chrome` container (PDF rendering)
- Persist volumes for Postgres data and MinIO storage

### Step 5: MCP servers

Create `/etc/nixos/hosts/common/mcp-servers.nix`

Systemd services for:
- `rxresume-mcp.service` — [Zaroganos/rxresume-mcp](https://github.com/Zaroganos/rxresume-mcp), points to local RxResume
- Gmail MCP and Mermaid MCP are cloud-hosted (Anthropic MCP), no local service needed

### Step 6: Enable everything in skyspy-dev.nix

```nix
imports = [
  # ... existing imports ...
  common/ollama.nix            # Step 1 (uncomment, was disabled — GPU auto-detected)
  common/openclaw.nix          # Step 2
  common/signal-cli.nix        # Step 3
  common/rxresume.nix          # Step 4
  common/mcp-servers.nix       # Step 5
];

# Only need to set models — acceleration auto-detected from nvidia.nix
local.ollama.models = [ "qwen2.5:14b" ];
```

Then `sudo nixos-rebuild switch`.

### Verification (Track 1)
1. `systemctl status ollama` — running, CUDA acceleration
2. `ollama list` — qwen2.5:14b present
3. `ollama run qwen2.5:14b "hello"` — responds
4. `systemctl status openclaw-gateway` — running on port 18789
5. Signal: send a message to OpenClaw's number → get a response
6. `curl http://localhost:3000` (or whatever port RxResume runs on) — RxResume UI loads

## Track 2: Recruiter Plugin

**Only starts after Track 1 is working.** Lives at `~/Code/github/logger/claw-recruiter/`.

### Architecture

**1 OpenClaw plugin** — the recruiter. All external services accessed via MCP or direct API.

MCP-agnostic design — discovers available MCP tools at startup, adapts:

| MCP available? | Feature unlocked | Fallback without it |
|---------------|-----------------|-------------------|
| **Gmail** | Inbox monitoring, draft creation | Drafts shown as text on Signal |
| **Mermaid Chart** | Visual funnel charts | Text-based stats |
| **RxResume** | Resume parsing, tailored PDF export | LLM-only resume parsing, no PDF |

### Interaction Model

1. Upload resume → plugin parses it → builds profile → auto-generates search terms
2. Background service scrapes job boards using those terms (every 6h)
3. Scores every job against your profile with local LLM
4. Notifies you on Signal when high-scoring matches found
5. You respond conversationally: "prep for that one", "how's my funnel?"

### Rate Limiting (per source)

Sources have aggressive anti-scraping. The pipeline must respect this:
- **Per-request delay**: 2-5 seconds between requests (with random jitter)
- **Per-source interval**: Minimum 6h between pipeline runs per source
- **Exponential backoff**: If a source returns errors/blocks, double the delay (cap at 24h)
- **Per-source toggle**: Disable a source without killing the whole pipeline
- **Configurable limits**: `maxResultsPerSource`, `delayBetweenRequests`, `minRunInterval`
- **Source-specific defaults**: LinkedIn (conservative, 3-5s delay), HN (permissive, 0.5s), Wellfound (moderate, 2s)

Optional future optimization: Use AirLLM (72B model, slow but high quality) for scoring during the wait time between rate-limited scrape requests — the slow inference fills the natural gaps.

### Domain Structure

```
src/
├── onboard/           # Parse resume, build profile, generate strategy
├── source/            # Job board scrapers (internal, not separate plugins)
│   ├── jobspy.ts      # LinkedIn + Indeed + Glassdoor (Python subprocess)
│   ├── hn.ts          # HackerNews Who's Hiring
│   └── wellfound.ts   # Wellfound/AngelList
├── match/             # Score jobs, curate shortlists
├── communicate/       # Email drafting, inbox monitoring (via Gmail MCP)
├── prepare/           # Resume tailoring (via RxResume MCP), company research
├── track/             # Application tracking, follow-ups, negotiation advice
├── learn/             # Outcome feedback → scoring calibration
├── report/            # Funnel stats, source effectiveness
├── mcp/               # MCP capability discovery + adapters
├── llm/               # Local LLM client (Ollama)
├── db/                # SQLite schema + queries
├── pipeline/          # Background orchestration + scheduling
├── notifications/     # Proactive Signal messages
└── tools/             # OpenClaw agent tools (10 tools)
```

### Agent Tools

| Tool | What user says | What recruiter does |
|------|---------------|-------------------|
| `recruiter_onboard` | "here's my resume" | Parse → profile → strategy → start sourcing |
| `recruiter_matches` | "what's new?" | Top unreviewed scored matches |
| `recruiter_job_detail` | "tell me about job 3" | Full info + company research |
| `recruiter_prepare` | "prep for that one" | Tailored resume PDF + talking points |
| `recruiter_track` | "I applied" / "got interview" / "rejected" | Stage tracking + follow-up timers |
| `recruiter_draft_email` | "follow up with Acme" | Draft email → approve on Signal → Gmail draft |
| `recruiter_check_inbox` | "any responses?" | Gmail search → status updates |
| `recruiter_stats` | "how am I doing?" | Funnel + source effectiveness + trends |
| `recruiter_preferences` | "no remote" / "minimum 150k" | Update profile, adjust scoring |
| `recruiter_advise` | "prep me for Acme interview" | Interview prep + negotiation advice |

### Dev Environment

`devenv.nix` in the repo for development:
- nodejs_22, pnpm, python312, sqlite, vitest

### Implementation Phases

1. **Skeleton + DB + Config** — Extension scaffolding, SQLite schema, types
2. **Profile + LLM client** — Resume upload, Ollama client, JSON parser
3. **Scoring engine** — 3-category rubric, robust JSON parsing
4. **Sources + Pipeline** — jobspy, HN, Wellfound scrapers + orchestration
5. **MCP Integration** — RxResume MCP for `recruiter_prepare`, Gmail MCP for email
6. **Background Service + Signal** — Scheduled pipeline, proactive notifications
7. **Tracking + Stats** — Application tracking, funnel analytics
8. **Learning Loop** — Outcome feedback → scoring calibration
9. **Communication** — Email drafting, inbox monitoring
10. **Advise** — Interview prep, company research, negotiation

### Database (SQLite)

- **profile** — skills, experience, education, location, salary, auto_search_terms
- **jobs** — source, title, employer, url, score, status, tailored_pdf_path, timestamps
- **stage_events** — application pipeline transitions
- **pipeline_runs** — scraping history
- **scoring_feedback** — learning loop data
- **settings** — preferences, calibration

### Verification (Track 2)
1. Extension loads into OpenClaw
2. Upload resume on Signal → profile extracted → search terms generated
3. Background scraping discovers jobs
4. Jobs scored by local Ollama
5. Signal notification: "Found N matches"
6. "Prep for job 2" → tailored PDF delivered on Signal
7. "How am I doing?" → funnel stats
8. After 20+ outcomes → scoring calibration active

## Key References

- `/etc/nixos/hosts/common/ollama.nix` — Existing Ollama module (ROCm, to fork for CUDA)
- `/etc/nixos/hosts/common/nvidia.nix` — CUDA already configured
- `/etc/nixos/hosts/skyspy-dev.nix` — Host config to update
- `/home/logger/Code/github/ai/openclaw/AGENTS.md` — OpenClaw dev guidelines
- `/home/logger/Code/github/ai/openclaw/extensions/memory-lancedb/index.ts` — Extension pattern
- `/home/logger/Code/github/ai/job-ops/orchestrator/src/server/services/llm/utils/json.ts` — JSON parser
- `/home/logger/Code/github/ai/job-ops/orchestrator/src/server/services/scorer.ts` — Scoring prompts
- `/home/logger/Code/github/ai/job-ops/extractors/jobspy/src/run.ts` — python-jobspy subprocess
- https://github.com/Zaroganos/rxresume-mcp — Pre-built RxResume MCP server
