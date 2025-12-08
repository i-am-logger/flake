# mynixos Agent System - Quick Start Guide

Get started with the mynixos multi-agent cybernetic system in 5 minutes.

## What You Have

A self-learning, coordinated AI system for mynixos development with:

- **7 specialized agents** for different tasks
- **Command & Control (C2)** message bus for coordination
- **Learning journals** that capture experience
- **Meta-learning** system that improves agents over time
- **Dynamic agent spawning** for specialized needs

## Basic Usage

### 1. Simple Task (Single Agent)

For straightforward tasks, invoke an agent directly:

```bash
# Ask architect for design advice
/mynixos-architect "Should GPU config go in hardware or features namespace?"

# Have engineer implement something
/mynixos-engineer "Add support for XYZ package"

# Get documentation written
/mynixos-documenter "Document the new ABC feature"

# Validate a build
/mynixos-validator "Test the latest changes"
```

### 2. Complex Task (Orchestrated)

For multi-step tasks, use the orchestrator:

```bash
# Orchestrator breaks down task and coordinates agents
/mynixos-orchestrator "Add NVIDIA GPU support to mynixos"

# Check progress
/status

# View agent communications
tail -f .claude/c2/messages.jsonl
```

## Example Workflows

### Adding a New Feature

```bash
# Let orchestrator coordinate the whole workflow
/mynixos-orchestrator "Add screen recording support for Wayland"

# Orchestrator will:
# 1. Analyze the request
# 2. Create task plan
# 3. Assign: Architect → Design API
# 4. Assign: Engineer → Implement
# 5. Assign: Validator → Test
# 6. Assign: Documenter → Document
# 7. Report completion
```

### Fixing a Bug

```bash
# Report the issue
/mynixos-orchestrator "Build fails with infinite recursion in hardware detection"

# Orchestrator will:
# 1. Assign validator to reproduce
# 2. Assign architect to analyze
# 3. Assign engineer to fix
# 4. Assign validator to verify
# 5. Update learning journals
```

### Refactoring Code

```bash
/mynixos-orchestrator "Split graphical.nix into smaller focused modules"

# Orchestrator coordinates:
# - Architect: Design new structure
# - Refactorer: Execute migration
# - Validator: Test compatibility
# - Documenter: Update docs
```

### Getting Design Advice

```bash
# Just ask the architect
/mynixos-architect "What's the best way to structure per-user GPU preferences?"

# Architect will:
# - Analyze the question
# - Review existing patterns
# - Recommend structure with rationale
# - Provide example code
```

## Monitoring the System

### Check Agent Status

```bash
# See what agents are doing
cat .claude/c2/agents.json | jq '.agents | to_entries[] | {name: .key, status: .value.status}'
```

### View Recent Activity

```bash
# Latest C2 messages
tail -20 .claude/c2/messages.jsonl | jq .

# Active tasks
cat .claude/c2/tasks.json | jq '.tasks'
```

### Read Learning Insights

```bash
# What architect learned recently
tail -50 .claude/learning/mynixos-architect.md

# What patterns engineer discovered
grep "## Patterns Discovered" -A 20 .claude/learning/mynixos-engineer.md
```

## Key Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `/mynixos-orchestrator` | Coordinate complex tasks | `/mynixos-orchestrator "Add XYZ"` |
| `/mynixos-architect` | Design & architecture | `/mynixos-architect "Where should X go?"` |
| `/mynixos-engineer` | Implementation | `/mynixos-engineer "Implement Y"` |
| `/mynixos-validator` | Testing & QA | `/mynixos-validator "Test Z"` |
| `/mynixos-refactorer` | Code refactoring | `/mynixos-refactorer "Clean up W"` |
| `/mynixos-documenter` | Documentation | `/mynixos-documenter "Document V"` |
| `/mynixos-meta-learner` | Learning analysis | `/mynixos-meta-learner` |
| `/status` | System status | `/status` |
| `/spawn-agent` | Create new agent | `/spawn-agent name "purpose"` |

## Decision Tree: Which Agent?

```
Need to do something in mynixos?
│
├─ Is it complex/multi-step?
│  └─ YES → Use /mynixos-orchestrator
│
├─ Need design advice?
│  └─ YES → Use /mynixos-architect
│
├─ Need implementation?
│  └─ YES → Use /mynixos-engineer
│
├─ Need testing/validation?
│  └─ YES → Use /mynixos-validator
│
├─ Need refactoring?
│  └─ YES → Use /mynixos-refactorer
│
├─ Need documentation?
│  └─ YES → Use /mynixos-documenter
│
└─ Analyzing agent performance?
   └─ YES → Use /mynixos-meta-learner
```

## Understanding Agent Coordination

When you use the orchestrator:

```
1. You: "Add NVIDIA support"
2. Orchestrator: Breaks into tasks
3. Architect: Designs API (posts to C2)
4. Engineer: Sees C2 message, implements
5. Engineer: Posts completion to C2
6. Validator: Sees completion, tests
7. Validator: Posts results to C2
8. Documenter: Sees results, documents
9. All agents: Update learning journals
10. Orchestrator: Reports to you
```

## Learning System

After each task, agents:

1. **Reflect**: What worked? What didn't?
2. **Record**: Update learning journal
3. **Request feedback**: Ask other agents
4. **Incorporate**: Apply feedback to improve
5. **Propose updates**: Suggest agent definition changes

Weekly, meta-learner:

1. **Reviews** all learning journals
2. **Identifies** patterns across agents
3. **Proposes** agent definition updates
4. **Tracks** effectiveness metrics

## Tips for Success

1. **Start with orchestrator** for complex tasks
2. **Use specific agents** for focused work
3. **Check C2 messages** to see coordination
4. **Read learning journals** to understand patterns
5. **Let agents learn** - they improve over time
6. **Provide feedback** when agents ask questions
7. **Trust the system** - agents coordinate automatically

## Common Patterns

### Feature Development
```bash
/mynixos-orchestrator "Add feature X"
# Architect → Engineer → Validator → Documenter
```

### Bug Fix
```bash
/mynixos-orchestrator "Fix bug Y"
# Validator → Architect → Engineer → Validator
```

### Refactoring
```bash
/mynixos-orchestrator "Refactor Z"
# Architect → Refactorer → Validator → Documenter
```

### Quick Question
```bash
/mynixos-architect "Should I use X or Y pattern?"
# Just architect, quick response
```

## Files to Know

```
.claude/
├── commands/           # Agent definitions (read these to understand agents)
├── c2/                 # Coordination system
│   ├── messages.jsonl # Agent communications (tail to see activity)
│   ├── tasks.json     # Active tasks (check progress)
│   └── agents.json    # Agent registry (see who's doing what)
├── learning/          # Learning journals (see insights gained)
└── AGENTS.md          # Full system documentation
```

## Next Steps

1. **Read** `.claude/AGENTS.md` for complete documentation
2. **Try** a simple task: `/mynixos-architect "Explain the priority system"`
3. **Try** a complex task: `/mynixos-orchestrator "Add support for XYZ"`
4. **Monitor** the C2 messages: `tail -f .claude/c2/messages.jsonl`
5. **Review** learnings: `cat .claude/learning/mynixos-*.md`

## Getting Help

- **Agent confused?** It will ask questions via C2
- **Task stuck?** Check `/status` for blockers
- **Want to understand?** Read learning journals
- **Need new capability?** `/spawn-agent new-specialist "purpose"`

---

**Welcome to the mynixos multi-agent system!**

Start with: `/mynixos-orchestrator "Help me understand how this works"`
