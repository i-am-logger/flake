# Agent Learning Journals

This directory contains learning journals for each mynixos agent. Agents update these journals after completing tasks to capture insights and improve over time.

## Purpose

Learning journals enable:
- **Experience capture**: Record what worked and what didn't
- **Pattern discovery**: Identify recurring issues and successes
- **Continuous improvement**: Update agent definitions based on learnings
- **Knowledge sharing**: Other agents learn from each other's experiences
- **Metrics tracking**: Monitor agent performance over time

## Structure

Each journal follows this template:

```markdown
# Agent Name Learning Journal

## Successes (What Works Well)
- Task outcomes that exceeded expectations
- Patterns that consistently work
- Effective approaches

## Improvements (What Needs Work)
- Issues encountered
- Root causes identified
- Actions to improve

## Patterns Discovered
- Repeatable patterns
- When they work/fail
- Best practices

## Feedback Received
- Input from other agents
- How feedback was incorporated
- Outcomes

## Self-Improvement Proposals
- Proposed changes to agent definition
- Rationale and expected impact
- Status tracking

## Metrics
- Task counts
- Success rates
- Trends
```

## Active Journals

- `mynixos-architect.md` - API design insights
- `mynixos-engineer.md` - Implementation learnings
- `mynixos-validator.md` - Testing patterns
- `mynixos-refactorer.md` - Refactoring strategies
- `mynixos-documenter.md` - Documentation best practices
- `mynixos-meta-learner.md` - Meta-level system insights

## Usage

### By Agents (After Task Completion)

```bash
# Append learning entry
cat >> .claude/learning/mynixos-<agent>.md << 'ENTRY'

### YYYY-MM-DD: Task Title
- **Situation**: What was the context
- **Action**: What you did
- **Outcome**: What happened
- **Learning**: Insight gained
- **Confidence**: High/Medium/Low

ENTRY
```

### By Meta-Learner (Weekly Review)

```bash
# Read all journals
cat .claude/learning/mynixos-*.md

# Identify patterns across agents
grep -h "## Patterns Discovered" -A 10 .claude/learning/*.md

# Track metrics
grep "Success Rate" .claude/learning/*.md
```

### By Users (Monitoring)

```bash
# Recent learnings
find .claude/learning -name "*.md" -exec tail -20 {} \;

# Specific agent insights
cat .claude/learning/mynixos-architect.md | grep "### 2024-12"
```

## Learning Cycle

1. **Agent completes task**
2. **Agent reflects** on outcome
3. **Agent records** in journal
4. **Agent requests** feedback from peers
5. **Other agents** respond with input
6. **Agent incorporates** feedback
7. **Meta-learner** reviews journals
8. **Meta-learner** identifies patterns
9. **Agent definitions** updated
10. **Improved behavior** in next task

## Metrics Tracked

- Tasks completed
- Success rate
- Feedback exchanges
- Patterns discovered
- Agent updates applied
- Trends (improving/stable/declining)

---

**Learning journals power the mynixos agent evolution system**
