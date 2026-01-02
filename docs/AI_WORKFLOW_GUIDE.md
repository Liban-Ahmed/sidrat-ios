# AI Development Workflow Guide for Sidrat

## Quick Start

### Option 1: Use Prompt Commands (Easiest)

In your AI chat, use these commands:
```
/plan-feature [describe feature]
# Creates implementation plan

/implement-story [paste plan or US-XXX]
# Implements the feature

/review-code [list files]
# Reviews implementation
```

### Option 2: Use Custom Agents Directly

1. **Planning**: Select `plan` agent → Describe feature → Get implementation plan
2. **Implementation**: Select `implement` agent → Provide plan → Get code
3. **Review**: Select `review` agent → Provide files → Get review

### Option 3: Manual Workflow

1. Ask AI to create implementation plan
2. Review and approve plan
3. Ask AI to implement based on plan
4. Ask AI to review implementation

## Typical Workflow

### Implementing a User Story
```
1. You: "Create a plan for implementing US-202: Lesson Player"
   
2. AI (plan agent):
   - Checks IMPLEMENTATION_STATUS.md
   - Reviews BUSINESS_LOGIC.md
   - Creates structured plan
   - Asks for approval

3. You: "Approved, proceed with implementation"
   
4. AI (implement agent):
   - Creates ViewModel
   - Creates View
   - Adds Preview
   - Tests offline
   
5. AI (review agent):
   - Checks standards
   - Verifies COPPA
   - Confirms business logic
   - Provides feedback
```

### Adding a New Feature (Not in User Stories)
```
1. You: "I want to add a feature that lets parents export progress reports as PDF"

2. AI (plan agent):
   - Researches PDF generation in iOS
   - Checks existing code patterns
   - Creates implementation plan
   - Notes COPPA implications
   
3. Review plan, provide feedback

4. Implement when approved
```

## Best Practices

### 1. Always Start with Planning
❌ Don't: "Just implement lesson player"  
✅ Do: "Create a plan for implementing lesson player (US-202)"

### 2. Reference Existing Docs
The AI has access to all context documents. Trust it to:
- Check implementation status
- Follow design system
- Apply business logic
- Maintain COPPA compliance

### 3. Iterate on Plans
Plans aren't perfect the first time:
- Review thoroughly
- Ask clarifying questions
- Request changes before implementation
- Approve explicitly

### 4. Test Implementations
After AI implements:
- Build the code
- Test on device
- Verify offline functionality
- Check acceptance criteria

### 5. Update Documentation
When implementation complete:
- Update IMPLEMENTATION_STATUS.md
- Add to CODEBASE_EXAMPLES.md if pattern-worthy
- Update BUSINESS_LOGIC.md if rules discovered

## Common Commands

### Planning
```
"Create a plan for US-XXX"
"Plan implementation of [feature]"
"I need a technical plan for [requirement]"
```

### Implementation
```
"Implement the plan we just created"
"Implement US-XXX following MVVM pattern"
"Create [FeatureName]View and [FeatureName]ViewModel"
```

### Review
```
"Review the implementation against the plan"
"Check if this code follows Sidrat standards"
"Is this COPPA compliant?"
```

### Questions
```
"What business logic applies to streak calculation?"
"Show me an example of a ViewModel in this codebase"
"What components are available in the design system?"
```

## Troubleshooting

### AI Isn't Following Standards
**Problem**: Code doesn't use Theme constants  
**Solution**: Remind it: "Please use Theme constants from docs/ARCHITECTURE.md"

### AI Creates Duplicate Code
**Problem**: Implements something that exists  
**Solution**: "Check docs/IMPLEMENTATION_STATUS.md first"

### AI Misses Business Rules
**Problem**: Calculation is wrong  
**Solution**: "Review streak calculation rules in docs/BUSINESS_LOGIC.md"

### Plan Too Vague
**Problem**: Tasks aren't specific enough  
**Solution**: "Break down Task 2 into more detailed subtasks"

## Tips for Success

1. **Be Specific**: "Create lesson player with 4 phases" > "Make lesson player"
2. **Reference Docs**: "Use the ViewModel pattern from CODEBASE_EXAMPLES"
3. **Approve Explicitly**: "Looks good, proceed" vs just moving on
4. **Iterate**: Plans and code improve with feedback
5. **Trust the Context**: AI has ALL your documentation already loaded

## Example Full Flow
```
You: "I want to implement the Parental Gate (US-104). Create a plan."

AI (plan agent):
- Checks IMPLEMENTATION_STATUS.md
- Reviews US-104 acceptance criteria
- Checks CODEBASE_EXAMPLES.md for view patterns
- Creates structured plan with:
  - ParentalGateView component
  - Math problem verification
  - Integration points
  - COPPA compliance notes

You: "The plan looks good but add a timeout feature - gate should dismiss after 30 seconds of no input"

AI (plan agent):
- Updates plan with timeout task
- Adds Timer to ViewModel
- Notes dismissal behavior

You: "Perfect, proceed with implementation"

AI (implement agent):
- Creates ParentalGateView.swift
- Implements math problem logic
- Adds timeout with Timer
- Includes Preview
- Uses Theme constants

AI: "Implementation complete. Here are the files created:"
- Shows code
- Confirms all acceptance criteria met

You: "Review this implementation"

AI (review agent):
- ✅ MVVM pattern correct
- ✅ Design system used
- ✅ COPPA compliant
- ✅ Preview included
- ⚠️ Suggests: Add accessibility label for math problem
- Verdict: Approved with minor suggestion

You: "Apply that suggestion"

AI (implement agent):
- Adds accessibility label
- Updates code

Done! ✅
```

---

With this workflow, you can confidently develop Sidrat features with AI assistance while maintaining code quality, standards compliance, and COPPA adherence.