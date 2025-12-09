# mynixos Command & Control (C2) System

This directory contains the command and control infrastructure for the mynixos multi-agent system.

## Structure

```
.claude/
├── commands/               # Agent definitions
│   ├── mynixos-architect.md
│   ├── mynixos-engineer.md
│   ├── mynixos-validator.md
│   ├── mynixos-refactorer.md
│   ├── mynixos-documenter.md
│   ├── mynixos-meta-learner.md
│   └── mynixos-orchestrator.md
│
├── c2/                    # Command & Control
│   ├── README.md         # This file
│   ├── messages.jsonl    # Message bus (append-only log)
│   ├── tasks.json        # Active task tracking
│   └── agents.json       # Agent registry
│
├── learning/              # Learning journals
│   ├── mynixos-architect.md
│   ├── mynixos-engineer.md
│   ├── mynixos-validator.md
│   ├── mynixos-refactorer.md
│   └── mynixos-documenter.md
│
└── artifacts/             # Shared artifacts
    └── [task-specific files]
```

## How It Works

### 1. User makes request
```
User: "Add NVIDIA GPU support"
```

### 2. Orchestrator activates
```bash
/mynixos-orchestrator
# Analyzes request
# Creates execution plan
# Assigns agents
```

### 3. Agents coordinate via C2
```
Orchestrator → Architect: "Design NVIDIA GPU API"
Architect → Engineer: "Here's the spec"
Engineer → Validator: "Implementation ready for test"
Validator → Documenter: "Tests pass, here's the data"
Documenter → Orchestrator: "Documentation complete"
Orchestrator → User: "Feature complete!"
```

### 4. Learning captured
Each agent updates their learning journal with insights gained.

### 5. System improves
Meta-learner analyzes journals and proposes agent improvements.

## Message Bus Protocol

### Posting a message
```bash
# Append to messages.jsonl
echo '{"ts":"2024-12-06T10:30:00Z","from":"mynixos-engineer","to":["mynixos-architect"],"type":"question","msg":"Should I use mkDefault?"}' >> .claude/c2/messages.jsonl
```

### Reading messages
```bash
# Latest 10 messages
tail -10 .claude/c2/messages.jsonl

# Messages for specific agent
grep '"to":\["mynixos-architect"\]' .claude/c2/messages.jsonl

# Messages about specific task
grep '"task":"nvidia-support"' .claude/c2/messages.jsonl
```

## Task Tracking

### View active tasks
```bash
cat .claude/c2/tasks.json | jq '.tasks'
```

### Check task status
```bash
cat .claude/c2/tasks.json | jq '.tasks["nvidia-gpu-support"]'
```

### Update task progress
```bash
# Use orchestrator to update task state
/orchestrate --update-task nvidia-gpu-support --status in_progress
```

## Agent Registry

### View active agents
```bash
cat .claude/c2/agents.json | jq '.agents'
```

### Check agent status
```bash
cat .claude/c2/agents.json | jq '.agents["mynixos-engineer"]'
```

### Register new agent
```bash
# Use orchestrator to spawn and register
/spawn-agent mynixos-new-specialist "Purpose"
```

## Workflows

### Complete Feature Development

1. **User Request** → `/mynixos-orchestrator`
2. **Orchestrator** analyzes and decomposes
3. **Architect** designs API
4. **Engineer** implements
5. **Validator** tests
6. **Documenter** documents
7. **Meta-learner** captures learnings
8. **Orchestrator** reports completion

### Bug Fix

1. **User Report** → `/mynixos-orchestrator`
2. **Orchestrator** triages
3. **Validator** reproduces
4. **Architect** analyzes (if architectural)
5. **Engineer** fixes
6. **Validator** verifies
7. **Meta-learner** records pattern

### Refactoring

1. **Improvement Identified** → `/mynixos-orchestrator`
2. **Architect** designs new structure
3. **Refactorer** plans migration
4. **All agents** review
5. **Refactorer** implements
6. **Validator** tests old and new
7. **Documenter** writes migration guide

## Communication Patterns

### Request-Response
```
Engineer: "Question for architect..."
Architect: "Answer is..."
Engineer: "Thanks, proceeding"
```

### Broadcast
```
Orchestrator: "New priority pattern for all"
All agents: "Acknowledged"
```

### Handoff
```
Architect: "Design complete, here's spec"
Engineer: "Received, implementing"
```

### Alert
```
Validator: "Build broken!"
Orchestrator: "Pausing workflow"
Engineer: "Investigating"
```

## Dynamic Agent Spawning

When needed, orchestrator spawns specialized agents:

```bash
# Example: Need ARM testing
/spawn-agent mynixos-arm-tester "Test ARM configurations"

# Agent created at:
.claude/commands/mynixos-arm-tester.md

# Registered in:
.claude/c2/agents.json

# Can be used immediately:
/mynixos-arm-tester "Test this on ARM"
```

## Learning System

Each agent maintains a learning journal:

```markdown
# mynixos-engineer Learning Journal

## 2024-12-06: NVIDIA GPU Implementation

### What Worked
- mkDefault pattern prevented recursion ✓
- Architect spec was clear ✓

### What Didn't
- Missed import statement initially ✗
- Should test builds more frequently ✗

### Learning
- Always verify imports before committing
- Build after each major change

### Action
- Add import checklist to workflow
```

Meta-learner reviews journals weekly and proposes agent improvements.

## Getting Started

### As Orchestrator (User)

```bash
# Start a task
/mynixos-orchestrator "Add feature X"

# Check status
/status

# View messages
tail .claude/c2/messages.jsonl
```

### As Agent (Developer)

```bash
# Receive assignment
# Check C2 for your tasks
grep '"to":\["mynixos-engineer"\]' .claude/c2/messages.jsonl | tail -1

# Post update
echo '{"ts":"'$(date -Iseconds)'","from":"mynixos-engineer","to":["orchestrator"],"type":"update","msg":"50% complete"}' >> .claude/c2/messages.jsonl

# Request feedback
echo '{"ts":"'$(date -Iseconds)'","from":"mynixos-engineer","to":["mynixos-architect"],"type":"question","msg":"Should I use X or Y?"}' >> .claude/c2/messages.jsonl

# Update learning journal
echo "## $(date +%Y-%m-%d): Task X
- Learning: Always do Y
" >> .claude/learning/mynixos-engineer.md
```

## Best Practices

1. **Clear Communication**: Be specific in C2 messages
2. **Regular Updates**: Post progress updates frequently
3. **Request Feedback**: Don't hesitate to ask other agents
4. **Record Learnings**: Update journal after each task
5. **Stay Coordinated**: Check C2 before major decisions
6. **Help Others**: Respond to questions from other agents

## Monitoring

### Task Dashboard (conceptual)
```
Active Tasks: 2
Completed Today: 5
Success Rate: 94%

Current:
- nvidia-gpu-support (60% - engineer implementing)
- docs-update (90% - documenter finalizing)

Agents:
✅ architect: idle
🔄 engineer: active (nvidia-gpu-support)
⏸️ validator: waiting
🔄 documenter: active (docs-update)
💤 refactorer: idle
💤 meta-learner: idle
```

## Troubleshooting

### Agent Not Responding
1. Check agent status: `cat .claude/c2/agents.json | jq '.agents["agent-name"]'`
2. Check for blockers in task: `cat .claude/c2/tasks.json | jq '.tasks["task-id"].blockers'`
3. Post alert to orchestrator

### Task Stuck
1. Check task status: `cat .claude/c2/tasks.json | jq '.tasks["task-id"]'`
2. Review C2 messages: `grep '"task":"task-id"' .claude/c2/messages.jsonl`
3. Identify blocker and escalate

### Communication Breakdown
1. Check message bus: `tail -20 .claude/c2/messages.jsonl`
2. Verify agents registered: `cat .claude/c2/agents.json`
3. Restart orchestrator if needed

---

**mynixos C2 System - Coordinating agents for effective NixOS development**
