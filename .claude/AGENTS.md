# mynixos Multi-Agent System

A cybernetic, self-learning command and control system for mynixos development.

## Overview

The mynixos agent system is a multi-agent AI framework that:
- **Coordinates** complex development tasks through intelligent decomposition
- **Communicates** via a structured command & control (C2) message bus
- **Learns** from experience through learning journals and feedback loops
- **Evolves** by updating agent definitions based on discovered patterns
- **Spawns** specialized agents dynamically when needed

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         USER                                │
│                  (makes requests)                           │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   ORCHESTRATOR                              │
│              (Command & Control Center)                     │
│  • Decomposes tasks                                        │
│  • Assigns to agents                                       │
│  • Coordinates communication                               │
│  • Spawns new agents                                       │
│  • Monitors progress                                       │
└────────┬────────┬────────┬────────┬────────┬───────┬───────┘
         │        │        │        │        │       │
         │        │        │        │        │       │
┌────────▼──┐ ┌──▼─────┐ ┌▼────────▼┐ ┌────▼────┐ ┌▼───────────┐
│ Architect │ │Engineer│ │Validator│ │Refactorer│ │Documenter │
│           │ │        │ │         │ │         │ │           │
│ Designs   │ │Implements│Tests    │ │Refactors│ │Documents  │
│ APIs      │ │Features │Systems  │ │Code     │ │Features   │
└─────┬─────┘ └───┬────┘ └────┬────┘ └────┬────┘ └─────┬─────┘
      │           │           │           │           │
      └───────────┴───────────┴───────────┴───────────┘
                          │
            ┌─────────────▼─────────────┐
            │      C2 Message Bus       │
            │  (Inter-agent comms)      │
            └─────────────┬─────────────┘
                          │
            ┌─────────────▼─────────────┐
            │     Meta-Learner          │
            │  • Analyzes journals      │
            │  • Identifies patterns    │
            │  • Proposes improvements  │
            │  • Updates agents         │
            └───────────────────────────┘
```

## Agents

### Core Permanent Agents

#### 1. mynixos-orchestrator (Command Center)
**Role**: Central coordinator and task decomposer
- Analyzes user requests
- Creates execution plans
- Assigns tasks to agents
- Monitors progress
- Spawns specialized agents
- Ensures completion

**Invoke**: `/mynixos-orchestrator <request>`

#### 2. mynixos-architect (API Designer)
**Role**: Architectural design and pattern guidance
- Designs API namespaces
- Recommends structures
- Evaluates trade-offs
- Ensures consistency
- Reviews implementations

**Invoke**: `/mynixos-architect <design-question>`

#### 3. mynixos-engineer (Implementer)
**Role**: Feature implementation and bug fixes
- Writes Nix modules
- Implements designs
- Fixes bugs
- Commits changes
- Builds systems

**Invoke**: `/mynixos-engineer <implementation-task>`

#### 4. mynixos-validator (Quality Assurance)
**Role**: Testing and validation
- Builds all systems
- Runs flake checks
- Tests features
- Validates quality
- Detects regressions

**Invoke**: `/mynixos-validator <test-task>`

#### 5. mynixos-refactorer (Code Improver)
**Role**: Refactoring and migration
- Improves code structure
- Manages deprecations
- Migrates patterns
- Maintains compatibility

**Invoke**: `/mynixos-refactorer <refactoring-task>`

#### 6. mynixos-documenter (Technical Writer)
**Role**: Documentation and examples
- Writes API docs
- Creates examples
- Writes guides
- Documents architecture
- Explains patterns

**Invoke**: `/mynixos-documenter <documentation-task>`

#### 7. mynixos-meta-learner (Learning Coordinator)
**Role**: Facilitates learning and improvement
- Analyzes learning journals
- Identifies patterns
- Proposes agent updates
- Coordinates feedback
- Tracks effectiveness

**Invoke**: `/mynixos-meta-learner`

### Dynamic Agents

The orchestrator can spawn specialized agents as needed:

```bash
# Example: Spawn NVIDIA GPU tester
/spawn-agent mynixos-nvidia-tester "Test NVIDIA configurations"

# Example: Spawn ARM architecture specialist
/spawn-agent mynixos-arm-specialist "ARM-specific development"

# Example: Spawn performance analyzer
/spawn-agent mynixos-perf-analyzer "Analyze build performance"
```

## How It Works

### 1. User Request Flow

```
User: "Add NVIDIA GPU support to mynixos"
  ↓
Orchestrator: Analyzes request
  ↓
Orchestrator: Decomposes into tasks:
  - Design API (architect)
  - Implement module (engineer)
  - Test on NVIDIA hardware (validator + new nvidia-tester)
  - Document feature (documenter)
  ↓
Orchestrator: Creates task plan and assigns agents
  ↓
Agents: Execute tasks, communicate via C2
  ↓
Orchestrator: Monitors and coordinates
  ↓
Orchestrator: Reports completion to user
```

### 2. Inter-Agent Communication

Agents communicate through the C2 message bus:

```json
{
  "from": "mynixos-engineer",
  "to": ["mynixos-architect"],
  "type": "question",
  "task": "nvidia-support",
  "msg": "Should NVIDIA detection use mkDefault?"
}

{
  "from": "mynixos-architect",
  "to": ["mynixos-engineer"],
  "type": "response",
  "task": "nvidia-support",
  "msg": "Yes, use mkDefault to prevent recursion"
}
```

### 3. Learning System

Each agent maintains a learning journal:

```markdown
## 2024-12-06: NVIDIA Implementation

### What Worked
- mkDefault prevented recursion ✓
- Clear architect spec ✓

### What Didn't
- Missed import initially ✗

### Learning
- Always verify imports before commit

### Action
- Add import checklist to workflow
```

Meta-learner reviews journals and updates agent definitions:

```markdown
## Agent Update: mynixos-engineer v1.1

**Added**: Pre-commit import verification checklist
**Reason**: 3 tasks missed imports in November
**Expected Impact**: Zero import errors
```

### 4. Cybernetic Feedback Loops

```
Task Completion
  ↓
Agent Reflection → Learning Journal Entry
  ↓
Request Peer Feedback → Other agents respond
  ↓
Incorporate Feedback → Update approach
  ↓
Meta-learner Analysis → Identify patterns
  ↓
Agent Definition Update → Improved behavior
  ↓
Apply to Next Task → Better results
```

## Getting Started

### For Users

```bash
# Start the orchestrator with your request
/mynixos-orchestrator "Add support for XYZ"

# Check task status
/status

# View agent communications
tail .claude/c2/messages.jsonl
```

### For Development

```bash
# View agent definitions
ls .claude/commands/mynixos-*.md

# Check agent status
cat .claude/c2/agents.json | jq '.agents'

# View active tasks
cat .claude/c2/tasks.json | jq '.tasks'

# Read learning journals
ls .claude/learning/mynixos-*.md
```

## Example Workflows

### Feature Development

```bash
# User request
/mynixos-orchestrator "Add Wayland screen recording support"

# Orchestrator decomposes:
# 1. Architect: Design screen recording API
# 2. Engineer: Implement wl-screenrec module
# 3. Validator: Test on Hyprland
# 4. Documenter: Write guide

# Agents coordinate via C2:
Architect → Engineer: "Here's the API spec"
Engineer → Validator: "Implementation ready"
Validator → Documenter: "Tests pass, here's data"

# Meta-learner captures patterns:
"Wayland feature pattern: Check compositor compatibility first"
```

### Bug Fix

```bash
# User reports
/mynixos-orchestrator "Build fails with infinite recursion in hardware detection"

# Orchestrator assigns:
# 1. Validator: Reproduce the issue
# 2. Architect: Analyze root cause
# 3. Engineer: Implement fix
# 4. Validator: Verify fix works

# Learning captured:
"Hardware modules must use mkDefault for my.hardware assignments"
```

### Refactoring

```bash
# Internal improvement
/mynixos-orchestrator "Refactor graphical.nix into smaller modules"

# Orchestrator coordinates:
# 1. Architect: Design module structure
# 2. Refactorer: Plan migration with compatibility
# 3. Refactorer: Execute split
# 4. Validator: Test old configs still work
# 5. Documenter: Update architecture docs

# Pattern recorded:
"Large module refactoring: Always maintain backwards compatibility"
```

## Agent Files

```
.claude/
├── commands/                    # Agent definitions
│   ├── mynixos-orchestrator.md # Command center
│   ├── mynixos-architect.md    # API designer
│   ├── mynixos-engineer.md     # Implementer
│   ├── mynixos-validator.md    # Tester
│   ├── mynixos-refactorer.md   # Refactorer
│   ├── mynixos-documenter.md   # Writer
│   └── mynixos-meta-learner.md # Learning coordinator
│
├── c2/                         # Command & Control
│   ├── README.md              # C2 system guide
│   ├── agents.json            # Agent registry
│   ├── tasks.json             # Task tracking
│   └── messages.jsonl         # Message bus
│
├── learning/                   # Learning journals
│   ├── mynixos-architect.md
│   ├── mynixos-engineer.md
│   ├── mynixos-validator.md
│   ├── mynixos-refactorer.md
│   └── mynixos-documenter.md
│
├── artifacts/                  # Shared work products
│   └── [task-specific files]
│
└── AGENTS.md                   # This file
```

## Key Principles

1. **Decomposition**: Complex tasks → small agent-sized pieces
2. **Coordination**: Agents work together through C2
3. **Learning**: Capture insights in journals
4. **Evolution**: Agents improve their own definitions
5. **Feedback**: Agents review each other's work
6. **Specialization**: Spawn new agents when needed
7. **Automation**: Minimize human intervention

## Benefits

- **Efficiency**: Parallel agent execution
- **Quality**: Specialized expertise per domain
- **Learning**: Continuous improvement from experience
- **Flexibility**: Spawn agents for new needs
- **Coordination**: Clear communication protocols
- **Traceability**: Full audit trail in C2 logs
- **Reliability**: Validated by QA agent

## Monitoring

View system health:

```bash
# Agent status
cat .claude/c2/agents.json | jq '.agents | to_entries[] | {name: .key, status: .value.status}'

# Recent messages
tail -20 .claude/c2/messages.jsonl | jq .

# Task progress
cat .claude/c2/tasks.json | jq '.tasks | to_entries[] | {task: .key, status: .value.status}'

# Learning insights
cat .claude/learning/mynixos-*.md | grep "## 2024-12" | head -10
```

## Future Enhancements

- **Real-time dashboard**: Web UI for monitoring
- **Metrics collection**: Detailed performance analytics
- **Agent versioning**: Track agent evolution over time
- **Knowledge base**: Centralized pattern library
- **Automated testing**: CI/CD integration
- **Multi-user support**: Coordinate across teams

---

**mynixos agents: Building NixOS configurations through coordinated intelligence**

For detailed information, see:
- `.claude/c2/README.md` - C2 system details
- `.claude/commands/*.md` - Individual agent definitions
- `.claude/learning/*.md` - Agent learning journals
