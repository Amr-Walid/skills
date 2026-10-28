#!/usr/bin/env python3
"""Validate every skills/<category>/<skill>/SKILL.md: frontmatter present, name/description set,
name matches folder, names unique across categories (required because installers flatten them)."""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "skills"
FM = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.S)

def parse(text):
    m = FM.match(text)
    if not m:
        return None
    data, key = {}, None
    for line in m.group(1).splitlines():
        kv = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if kv:
            key = kv.group(1); data[key] = kv.group(2).strip()
        elif key and line.startswith((" ", "\t")):
            data[key] = (data[key] + " " + line.strip()).strip()
    for k, v in data.items():
        if v in (">", "|", ">-", "|-"):
            data[k] = ""
        data[k] = data[k].lstrip(">|- ").strip().strip('"').strip("'")
    return data

def main():
    errors, seen = [], {}
    skills = sorted(ROOT.glob("*/*/SKILL.md"))
    for p in skills:
        folder = p.parent.name
        meta = parse(p.read_text(encoding="utf-8"))
        rel = p.relative_to(ROOT.parent)
        if meta is None:
            errors.append(f"{rel}: missing YAML frontmatter"); continue
        if not meta.get("name"):
            errors.append(f"{rel}: missing 'name'")
        elif meta["name"] != folder:
            errors.append(f"{rel}: name '{meta['name']}' != folder '{folder}'")
        if not meta.get("description"):
            errors.append(f"{rel}: missing 'description'")
        if folder in seen:
            errors.append(f"{rel}: duplicate skill name (also in {seen[folder]})")
        seen[folder] = rel
    print(f"Checked {len(skills)} skills.")
    for e in errors:
        print("ERROR:", e)
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())
