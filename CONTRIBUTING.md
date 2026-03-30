# Contributing

## Adding a new adapter

An adapter converts `content/` into the format a specific AI tool expects.

### Structure

```
adapters/
  your-tool/
    convert.sh     ← the only required file
```

`convert.sh` receives `--source <path>` pointing to a `content/`-compatible
directory and installs files into the tool's expected location.

### Minimal convert.sh

```bash
#!/usr/bin/env bash
# adapters/your-tool/convert.sh

set -euo pipefail

CONTENT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) CONTENT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -d "$CONTENT_DIR" ]] || { echo "No content dir: $CONTENT_DIR" >&2; exit 1; }

DEST="${HOME}/.your-tool/agents"
mkdir -p "$DEST"

# Copy and transform content/ files into tool-specific format
cp "$CONTENT_DIR/role.md" "$DEST/role.md"
# ... etc

echo "✓ Installed to $DEST"
```

### Registration

Add your tool to `install.sh` in three places:

**1. `ALL_TOOLS` array:**
```bash
ALL_TOOLS=(claude-code antigravity your-tool)
```

**2. Detection function:**
```bash
detect_your_tool() {
  command -v your-tool &>/dev/null || [[ -d "${HOME}/.your-tool" ]]
}
```

**3. Detection loop:**
```bash
your-tool) detect_your_tool && TOOL_DETECTED[$tool]=1 || TOOL_DETECTED[$tool]=0 ;;
```

**4. Label:**
```bash
[your-tool]="Your Tool   (~/.your-tool/agents/)"
```

### Requirements

- Script must accept `--source <path>` and `--help`
- Script must be idempotent (safe to run twice)
- Back up existing files before overwriting
- Print what was installed (one line per file or directory)
- Exit 0 on success, non-zero on failure

### Testing

```bash
# Test your adapter in isolation
cd ~/projects/some-project
/path/to/agent-config-template/adapters/your-tool/convert.sh \
  --source /path/to/agent-config-template/content

# Test via install.sh
/path/to/agent-config-template/install.sh --tool your-tool

# Test with the Eargrade example
/path/to/agent-config-template/install.sh \
  --source /path/to/agent-config-template/examples/eargrade \
  --tool your-tool
```

---

## Improving existing content

`content/` files are templates — they should work for any project.
When improving them, check two things:

1. Does `examples/eargrade/` still reflect the template structure?
   If you add a new section to `content/role.md`, add the filled-in
   version to `examples/eargrade/role.md`.

2. Does `docs/usage.md` still accurately describe the fill-in process?
   If you add a new file to `content/`, add it to the Step 2 list in usage.md.

---

## Reporting stale content

If a file in `content/` or `examples/` refers to outdated tools, patterns,
or conventions — open an issue with:

- Which file and which section
- What it currently says
- What it should say instead
- Why (what changed)

Stale agent configs cause confident mistakes. Reports are high value.
