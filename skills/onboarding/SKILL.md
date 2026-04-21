---
name: onboarding
description: Guided onboarding orchestrator — scans your repo, infers your use case, and dispatches to the right setup skill. Run this if you're new and want a personalized Claude Code setup.
---

# Claude Onboarding Agent

Welcome. This skill scans your project, asks you one question, and then configures Claude exactly the way you need it.

## Step 1: Detect Language

Read the user's first message. Detect the language (e.g., English, German, Spanish, French). Respond in that language for the entire session. All generated file comments also use that language. Technical field names, tool names, and code remain in English regardless of detected language.

## Step 2: Scan the Repository

Before asking anything, silently scan the current directory:

- Count file extensions: `.py`, `.ts`, `.js`, `.go`, `.rs`, `.rb`, `.java`, `.cs` → coding signal
- Look for package manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `requirements.txt` → strong coding signal
- Look for `.ipynb` files, a `notebooks/` folder, `data/raw/`, or deps on `pandas`/`polars`/`numpy`/`scikit-learn`/`torch`/`jax` in `pyproject.toml` → data-science signal (this should dominate a generic Python coding signal when present)
- Look for `.tex`, `.bib` files → research signal
- Look for `*.docx`, `*.pptx`, `*.pdf`, `*.xlsx` files → office signal
- Look for a `notes/`, `vault/`, `wiki/`, `obsidian/` directory → knowledge base signal
- Check if `CLAUDE.md` already exists → set `existing_claude_md: true`
- Check if `AGENTS.md` already exists

Infer the most likely use case based on the strongest signal. If no clear signal exists, make no inference.

**If CLAUDE.md already exists:** Before presenting options, inform the user: "I found an existing CLAUDE.md. The setup skill will extend it (adding a new section) rather than overwriting it."

## Step 3: Present Options

Present all 5 options. If an inference was made, place it at position 1 with a short note explaining what was detected. If no inference, present all options equally.

Example format (adapt wording to detected language):

---

**Which setup would you like?**

1. [Inferred: Coding Setup] — looks like a Python project (pyproject.toml detected)
2. Data Science / ML — notebooks, experiment tracking, reproducible pipelines
3. Knowledge Base & Documentation — build a structured wiki from code or notes
4. Office & Business Productivity — emails, reports, presentations
5. Research & Academic Writing — literature, papers, LaTeX
6. Content Creation — YouTube, social media, newsletters
7. DevOps / Cloud Engineering — CI/CD, Kubernetes, Terraform, cloud providers
8. UI/UX Design — component design, Figma handoff, accessibility
9. Already set up — audit my current Claude configuration (`/tipps`)
10. Not sure — help me decide

---

## Step 4: Handle "Not Sure"

If the user picks option 10, ask these 6 yes/no questions one at a time:

1. "Are you primarily using Claude to work with code or a codebase?" → yes → recommend Coding Setup
2. "Do you mainly work with notebooks, datasets, or ML models?" → yes → recommend Data Science Setup
3. "Are you trying to organize documents, notes, or code into a structured knowledge base or wiki?" → yes → recommend Knowledge Base Builder
4. "Do you mostly work with documents, emails, reports, or presentations?" → yes → recommend Office Setup
5. "Do you manage infrastructure, CI/CD pipelines, or cloud resources?" → yes → recommend DevOps Setup
6. "Do you primarily work with UI designs, components, or frontend interfaces?" → yes → recommend Design Setup

If none match after 6 questions, present all 8 setup options (1–8, excluding "Already set up" and "Not sure") with one-line descriptions and ask the user to pick a number.

## Step 5: Dispatch

Once the user confirms a choice, pass the following handoff context inline and invoke the chosen skill:

```
HANDOFF_CONTEXT:
  detected_language: "[ISO 639-1 code, e.g. en, de, es]"
  existing_claude_md: [true/false]
  inferred_use_case: "[coding|data-science|knowledge-base|office|research|content-creator|devops|design|unknown]"
  repo_signals: ["[list of detected signals, e.g. pyproject.toml, *.py files, *.ipynb]"]
```

Skill routing:
- Coding Setup → invoke `coding-setup` skill
- Data Science / ML → invoke `data-science-setup` skill
- Knowledge Base → invoke `knowledge-base-builder` skill
- Office → invoke `office-setup` skill
- Research → invoke `research-setup` skill
- Content Creator → invoke `content-creator-setup` skill
- DevOps Setup → invoke `devops-setup` skill
- UI/UX Design Setup → invoke `design-setup` skill
- Already set up (audit) → invoke `tipps` skill

Step back completely. The setup skill handles everything from here.
