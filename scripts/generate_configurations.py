#!/usr/bin/env python3
"""Generate [Name]Configuration.swift files for all rules.

Reads each *Rule.swift file, extracts the RuleDescription metadata,
and creates a corresponding *Configuration.swift file with a struct
conforming to RuleConfiguration.

Also updates the rule file to add `static let configuration = [Name]Configuration()`
before the existing description block.
"""

import os
import re
import sys
from pathlib import Path


def find_rule_files(root: str) -> list[Path]:
    """Find all rule files that have a RuleDescription."""
    rules_dir = Path(root) / "Sources" / "Swiftiomatic" / "Rules"
    result = []
    for path in sorted(rules_dir.rglob("*Rule.swift")):
        if path.name in (
            "Rule.swift",
            "SwiftSyntaxRule.swift",
            "SwiftSyntaxCorrectableRule.swift",
            "CollectingRule.swift",
            "FormatRule.swift",
        ):
            continue
        content = path.read_text()
        if "static let description = RuleDescription(" in content:
            result.append(path)
    return result


def extract_rule_name(path: Path) -> str:
    """Extract the rule struct name from the file."""
    content = path.read_text()
    m = re.search(r"struct (\w+Rule)\b", content)
    if m:
        return m.group(1)
    return path.stem


def find_description_line_start(content: str) -> int:
    """Find the start of the line containing 'static let description = RuleDescription('."""
    idx = content.find("static let description = RuleDescription(")
    if idx == -1:
        return -1
    return content.rfind("\n", 0, idx) + 1


def extract_description_value(content: str, key: str) -> str | None:
    """Extract a simple string value from the RuleDescription block.
    Handles multi-line string concatenation with + operator."""
    # Find the block first
    block_start = content.find("static let description = RuleDescription(")
    if block_start == -1:
        return None

    # Find the key
    pattern = rf'{key}:\s*"'
    m = re.search(pattern, content[block_start:])
    if not m:
        return None

    # Extract the first string part
    start = block_start + m.end()
    parts = []

    while True:
        # Find the closing quote
        end = start
        while end < len(content):
            if content[end] == "\\" and end + 1 < len(content):
                end += 2
                continue
            if content[end] == '"':
                break
            end += 1

        parts.append(content[start:end])
        end += 1  # past the closing quote

        # Check if there's a + continuation
        rest = content[end:end + 50].lstrip()
        if rest.startswith('+'):
            # Find the next quote
            plus_pos = content.index('+', end)
            next_quote = content.index('"', plus_pos + 1)
            start = next_quote + 1
        else:
            break

    return "".join(parts)


def extract_bool_value(content: str, key: str, block_start: int) -> bool | None:
    """Extract a boolean value from the RuleDescription block."""
    # Search within the description block only
    block = content[block_start:]
    # Find the end of the description block
    m = re.search(rf"{key}:\s*(true|false)", block)
    if m:
        return m.group(1) == "true"
    return None


def extract_scope(content: str, block_start: int) -> str | None:
    """Extract the scope value."""
    block = content[block_start:]
    m = re.search(r"scope:\s*\.(\w+)", block)
    if m:
        return m.group(1)
    return None


def extract_deprecated_aliases(content: str, block_start: int) -> str | None:
    """Extract deprecatedAliases value."""
    block = content[block_start:]
    m = re.search(r"deprecatedAliases:\s*(\[[^\]]+\])", block)
    if m:
        return m.group(1)
    return None


def config_name(rule_name: str) -> str:
    """Get the Configuration type name from a rule name."""
    if rule_name.endswith("Rule"):
        return rule_name[:-4] + "Configuration"
    return rule_name + "Configuration"


def check_rule_conformances(content: str, rule_name: str) -> dict:
    """Check what protocols the rule conforms to."""
    result = {}
    correctable_patterns = [
        rf"{rule_name}\s*:\s*.*SwiftSyntaxCorrectableRule",
        rf"extension\s+{rule_name}\s*:\s*.*SwiftSyntaxCorrectableRule",
        rf"extension\s+{rule_name}\s*:\s*.*CorrectableRule",
        rf"{rule_name}\s*:\s*.*CorrectableRule",
        rf"extension\s+{rule_name}\s*:\s*.*SubstitutionCorrectableRule",
        rf"{rule_name}\s*:\s*.*SubstitutionCorrectableRule",
    ]
    for p in correctable_patterns:
        if re.search(p, content):
            result["isCorrectable"] = True
            break

    collecting_patterns = [
        rf"extension\s+{rule_name}\s*:\s*.*CollectingRule",
        rf"{rule_name}\s*:\s*.*CollectingRule",
    ]
    for p in collecting_patterns:
        if re.search(p, content):
            result["isCrossFile"] = True
            break

    enrichable_patterns = [
        rf"extension\s+{rule_name}\s*:\s*.*AsyncEnrichableRule",
        rf"{rule_name}\s*:\s*.*AsyncEnrichableRule",
    ]
    for p in enrichable_patterns:
        if re.search(p, content):
            result["canEnrichAsync"] = True
            break

    return result


def generate_configuration_struct(rule_name: str, identifier: str, name: str,
                                   summary: str, scope: str | None,
                                   is_opt_in: bool, requires_sourcekit: bool,
                                   requires_compiler_args: bool,
                                   requires_file_on_disk: bool,
                                   deprecated_aliases: str | None,
                                   conformances: dict) -> str:
    """Generate the Configuration struct content."""
    cname = config_name(rule_name)
    lines = []
    lines.append(f"struct {cname}: RuleConfiguration {{")
    lines.append(f'    let id = "{identifier}"')
    lines.append(f'    let name = "{name}"')

    # Handle summary that might contain special characters
    if len(summary) > 100:
        # Use multi-line for long summaries
        lines.append(f'    let summary = "{summary}"')
    else:
        lines.append(f'    let summary = "{summary}"')

    # Non-default properties
    if scope and scope != "lint":
        lines.append(f"    let scope: Scope = .{scope}")

    if conformances.get("isCorrectable"):
        lines.append("    let isCorrectable = true")

    if is_opt_in:
        lines.append("    let isOptIn = true")

    if requires_sourcekit:
        lines.append("    let requiresSourceKit = true")

    if requires_compiler_args:
        lines.append("    let requiresCompilerArguments = true")

    if requires_file_on_disk:
        lines.append("    let requiresFileOnDisk = true")

    if conformances.get("isCrossFile"):
        lines.append("    let isCrossFile = true")

    if conformances.get("canEnrichAsync"):
        lines.append("    let canEnrichAsync = true")

    if deprecated_aliases:
        lines.append(f"    let deprecatedAliases: Set<String> = {deprecated_aliases}")

    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def main():
    root = os.environ.get("PROJECT_ROOT", ".")
    rule_files = find_rule_files(root)
    print(f"Found {len(rule_files)} rule files")

    created = 0
    updated = 0
    errors = []

    for path in rule_files:
        content = path.read_text()
        rule_name = extract_rule_name(path)
        cname = config_name(rule_name)

        block_start = find_description_line_start(content)
        if block_start == -1:
            errors.append(f"Could not find description in {path}")
            continue

        # Extract metadata
        identifier = extract_description_value(content, "identifier")
        name_val = extract_description_value(content, "name")
        summary = extract_description_value(content, "description")

        if not identifier or not name_val or summary is None:
            errors.append(f"Could not extract required fields from {path}: id={identifier}, name={name_val}, summary={summary}")
            continue

        is_opt_in = extract_bool_value(content, "isOptIn", block_start) or False
        requires_sourcekit = extract_bool_value(content, "requiresSourceKit", block_start) or False
        requires_compiler_args = extract_bool_value(content, "requiresCompilerArguments", block_start) or False
        requires_file_on_disk = extract_bool_value(content, "requiresFileOnDisk", block_start) or False
        scope = extract_scope(content, block_start)
        deprecated_aliases = extract_deprecated_aliases(content, block_start)

        conformances = check_rule_conformances(content, rule_name)

        # Generate Configuration file
        config_content = generate_configuration_struct(
            rule_name, identifier, name_val, summary, scope,
            is_opt_in, requires_sourcekit, requires_compiler_args,
            requires_file_on_disk, deprecated_aliases, conformances,
        )

        # Configuration file goes in the same directory as the rule
        config_filename = f"{cname.replace('Configuration', '')}Configuration.swift"
        config_path = path.parent / config_filename

        if config_path.exists():
            errors.append(f"Configuration file already exists: {config_path}")
            continue

        config_path.write_text(config_content)
        created += 1

        # Update the rule file: add configuration line before description
        # Detect indentation from the description line
        desc_line = content[block_start:]
        indent_match = re.match(r"(\s*)", desc_line)
        indent = indent_match.group(1) if indent_match else "    "

        config_line = f"{indent}static let configuration = {cname}()\n\n"

        new_content = content[:block_start] + config_line + content[block_start:]
        path.write_text(new_content)
        updated += 1

    print(f"Created {created} configuration files")
    print(f"Updated {updated} rule files")
    if errors:
        print(f"\nErrors ({len(errors)}):")
        for e in errors:
            print(f"  {e}")


if __name__ == "__main__":
    main()
