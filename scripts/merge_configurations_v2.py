#!/usr/bin/env python3
"""
Merge RuleConfiguration structs into their corresponding Rule files.

Uses indentation-based line processing — no brace matching or string parsing.
Each Configuration file's body lines are extracted and `static` is added to
top-level `let`/`var`/`func` declarations that don't already have it.

Usage: python3 scripts/merge_configurations_v2.py [--dry-run]
"""

import os
import re
import sys

SOURCES_ROOT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Sources", "Swiftiomatic", "Rules",
)

SKIP_FILES = {"RuleConfiguration.swift"}


def find_configuration_files():
    results = []
    for root, dirs, files in os.walk(SOURCES_ROOT):
        for f in sorted(files):
            if f.endswith("Configuration.swift") and f not in SKIP_FILES:
                results.append(os.path.join(root, f))
    return sorted(results)


def find_rule_file(config_path):
    directory = os.path.dirname(config_path)
    basename = os.path.basename(config_path)
    rule_name = basename.replace("Configuration.swift", "Rule.swift")
    rule_path = os.path.join(directory, rule_name)
    if os.path.exists(rule_path):
        return rule_path
    return None


def extract_body_lines(config_content):
    """Extract lines between the struct declaration opening brace and the final closing brace."""
    lines = config_content.split('\n')

    # Find struct declaration line
    struct_line_idx = None
    for i, line in enumerate(lines):
        if re.match(r'\s*struct\s+\w+Configuration\s*:\s*RuleConfiguration\s*\{', line):
            struct_line_idx = i
            break

    if struct_line_idx is None:
        return None, None

    # Extract struct name
    m = re.search(r'struct\s+(\w+Configuration)', lines[struct_line_idx])
    struct_name = m.group(1) if m else None

    # Find the last closing brace at column 0 (the struct's closing brace)
    last_close_idx = None
    for i in range(len(lines) - 1, struct_line_idx, -1):
        if lines[i].strip() == '}':
            last_close_idx = i
            break

    if last_close_idx is None:
        return struct_name, []

    # Body is everything between struct line and closing brace
    body_lines = lines[struct_line_idx + 1:last_close_idx]
    return struct_name, body_lines


def add_static_to_body(body_lines):
    """Add `static` to top-level declarations that don't already have it.

    A top-level declaration is identified by having exactly the struct's
    member indentation (2 or 4 spaces) and starting with a declaration keyword
    (optionally preceded by access modifiers).
    """
    if not body_lines:
        return body_lines

    # Detect indentation level from the first non-empty line
    indent_size = None
    for line in body_lines:
        stripped = line.lstrip()
        if stripped and not stripped.startswith('//'):
            indent_size = len(line) - len(stripped)
            break

    if indent_size is None:
        return body_lines

    result = []
    for line in body_lines:
        stripped = line.lstrip()
        line_indent = len(line) - len(stripped)

        if line_indent == indent_size and stripped:
            # Top-level declaration — check if it needs `static`
            if 'static ' in stripped[:30]:
                # Already has static (e.g. "private static let ...")
                result.append(line)
            elif re.match(r'(let|var|func)\s', stripped):
                # Simple declaration: let/var/func
                indent = ' ' * indent_size
                result.append(f'{indent}static {stripped}')
            elif re.match(r'(private|internal|public|fileprivate|open)\s+(let|var|func)\s', stripped):
                # Access-modified declaration
                m = re.match(r'(private|internal|public|fileprivate|open)(\s+)', stripped)
                indent = ' ' * indent_size
                result.append(f'{indent}{m.group(1)}{m.group(2)}static {stripped[m.end():]}')
            else:
                result.append(line)
        else:
            result.append(line)

    return result


def modify_rule_file(rule_content, static_body_lines, config_struct_name):
    """Remove `static let configuration = ...` and insert extracted properties."""
    lines = rule_content.split('\n')

    # Find and remove the `static let configuration = FooConfiguration()` line
    config_pattern = re.compile(
        r'^\s*static\s+let\s+configuration\s*=\s*' + re.escape(config_struct_name) + r'\(\)\s*$'
    )
    config_line_idx = None
    for i, line in enumerate(lines):
        if config_pattern.match(line):
            config_line_idx = i
            break

    if config_line_idx is None:
        return None

    # Remove the configuration line (and trailing blank line if present)
    del lines[config_line_idx]
    if config_line_idx < len(lines) and lines[config_line_idx].strip() == '':
        del lines[config_line_idx]

    # Find the struct opening brace (may span multiple lines for long conformance lists)
    struct_line_idx = None
    for i, line in enumerate(lines):
        if re.match(r'^struct\s+\w+', line):
            # Found struct declaration — now find the opening brace
            # It may be on this line or a subsequent line
            if '{' in line:
                struct_line_idx = i
                break
            else:
                # Look ahead for the opening brace
                for j in range(i + 1, min(i + 5, len(lines))):
                    if '{' in lines[j]:
                        struct_line_idx = j
                        break
                break

    if struct_line_idx is None:
        return None

    # Insert the static properties after the struct opening brace
    insert_idx = struct_line_idx + 1
    new_lines = lines[:insert_idx] + static_body_lines + lines[insert_idx:]

    return '\n'.join(new_lines)


def process_file(config_path, dry_run=False):
    rule_path = find_rule_file(config_path)
    if not rule_path:
        print(f"  SKIP (no rule file): {os.path.basename(config_path)}")
        return False

    with open(config_path, 'r') as f:
        config_content = f.read()

    struct_name, body_lines = extract_body_lines(config_content)
    if body_lines is None:
        print(f"  SKIP (no struct): {os.path.basename(config_path)}")
        return False

    if not body_lines:
        print(f"  SKIP (empty body): {os.path.basename(config_path)}")
        return False

    static_body_lines = add_static_to_body(body_lines)

    with open(rule_path, 'r') as f:
        rule_content = f.read()

    new_rule_content = modify_rule_file(rule_content, static_body_lines, struct_name)
    if new_rule_content is None:
        print(f"  SKIP (can't modify rule): {os.path.basename(config_path)} -> {os.path.basename(rule_path)}")
        return False

    if dry_run:
        print(f"  MERGE: {os.path.basename(config_path)} -> {os.path.basename(rule_path)}")
        return True

    with open(rule_path, 'w') as f:
        f.write(new_rule_content)

    os.remove(config_path)
    print(f"  MERGED: {os.path.basename(config_path)} -> {os.path.basename(rule_path)}")
    return True


def main():
    dry_run = "--dry-run" in sys.argv
    config_files = find_configuration_files()
    print(f"Found {len(config_files)} Configuration files")

    success = 0
    skipped = 0
    for path in config_files:
        if process_file(path, dry_run):
            success += 1
        else:
            skipped += 1

    print(f"\nResults: {success} merged, {skipped} skipped")
    if dry_run:
        print("(dry run — no files were modified)")


if __name__ == "__main__":
    main()
