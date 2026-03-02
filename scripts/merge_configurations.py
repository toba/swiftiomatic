#!/usr/bin/env python3
"""
Merge RuleConfiguration structs into their corresponding Rule files.

For each *Configuration.swift file under Sources/Swiftiomatic/Rules/:
1. Extract the full struct body from the Configuration file
2. Convert instance properties to static properties
3. Insert them into the corresponding *Rule.swift struct
4. Remove the `static let configuration = *Configuration()` line from the rule
5. Delete the Configuration.swift file

Usage: python3 scripts/merge_configurations.py [--dry-run]
"""

import os
import re
import sys

SOURCES_ROOT = os.path.join(os.path.dirname(os.path.dirname(__file__)), "Sources", "Swiftiomatic", "Rules")

SKIP_FILES = {"RuleConfiguration.swift"}
SKIP_DIRS = {"Configuration", "Models"}


def find_configuration_files():
    results = []
    for root, dirs, files in os.walk(SOURCES_ROOT):
        rel = os.path.relpath(root, SOURCES_ROOT)
        if rel.split(os.sep)[0] in SKIP_DIRS:
            continue
        for f in files:
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


class SwiftTokenizer:
    """Track string/comment state while scanning Swift source."""

    def __init__(self, text):
        self.text = text
        self.pos = 0

    def at_end(self):
        return self.pos >= len(self.text)

    def peek(self, n=1):
        return self.text[self.pos:self.pos + n]

    def advance(self, n=1):
        self.pos += n

    def skip_whitespace_and_comments(self):
        """Skip whitespace and comments, return True if anything skipped."""
        start = self.pos
        while not self.at_end():
            if self.text[self.pos] in ' \t\n\r':
                self.pos += 1
            elif self.peek(2) == '//':
                while not self.at_end() and self.text[self.pos] != '\n':
                    self.pos += 1
            elif self.peek(2) == '/*':
                depth = 1
                self.pos += 2
                while not self.at_end() and depth > 0:
                    if self.peek(2) == '/*':
                        depth += 1
                        self.pos += 2
                    elif self.peek(2) == '*/':
                        depth -= 1
                        self.pos += 2
                    else:
                        self.pos += 1
            else:
                break
        return self.pos > start

    def skip_string(self):
        """Skip a string literal starting at current position.
        Handles #"..."#, \"\"\"...\"\"\" etc.
        Returns True if a complete string was found, False if unterminated."""
        # Count leading pounds
        pounds = 0
        while not self.at_end() and self.text[self.pos] == '#':
            pounds += 1
            self.pos += 1

        if self.at_end() or self.text[self.pos] != '"':
            return False  # not a string

        # Check for multi-line string
        if self.peek(3) == '"""':
            self.pos += 3
            closing = '"""' + '#' * pounds
            idx = self.text.find(closing, self.pos)
            if idx == -1:
                self.pos = len(self.text)
                return False  # unterminated
            self.pos = idx + len(closing)
            return True
        else:
            self.pos += 1  # skip opening "
            closing_quote = '"' + '#' * pounds
            while not self.at_end():
                ch = self.text[self.pos]
                if ch == '\\' and pounds == 0:
                    self.pos += 2
                    continue
                if self.text[self.pos:self.pos + len(closing_quote)] == closing_quote:
                    self.pos += len(closing_quote)
                    return True
                self.pos += 1
            return False  # unterminated


def find_balanced_end(text, start):
    """Find the position after the matching closing brace, handling strings/comments."""
    tok = SwiftTokenizer(text)
    tok.pos = start
    depth = 1

    while not tok.at_end() and depth > 0:
        ch = tok.text[tok.pos]

        if ch == '/' and tok.peek(2) in ('//', '/*'):
            tok.skip_whitespace_and_comments()
            continue

        if ch == '#' or ch == '"':
            # Might be a string
            save = tok.pos
            tok.skip_string()
            if tok.pos > save:
                continue

        if ch == '{':
            depth += 1
            tok.pos += 1
        elif ch == '}':
            depth -= 1
            tok.pos += 1
        else:
            tok.pos += 1

    return tok.pos


def find_struct_body(content):
    """Find the body of the RuleConfiguration struct."""
    struct_match = re.search(r'struct\s+(\w+Configuration)\s*:\s*RuleConfiguration\s*\{', content)
    if not struct_match:
        return None, None

    struct_name = struct_match.group(1)
    body_start = struct_match.end()
    body_end = find_balanced_end(content, body_start)

    # body_end points past the closing }, we want content between { and }
    return struct_name, content[body_start:body_end - 1]


def is_property_complete(text):
    """Check if a property declaration is complete (balanced braces/strings)."""
    tok = SwiftTokenizer(text)
    brace_depth = 0
    found_brace = False

    while not tok.at_end():
        ch = tok.text[tok.pos]

        if ch == '/' and tok.peek(2) in ('//', '/*'):
            tok.skip_whitespace_and_comments()
            continue

        if ch == '#' or ch == '"':
            save = tok.pos
            found = tok.skip_string()
            if tok.pos > save:
                if not found:
                    return False  # unterminated string
                continue

        if ch == '{':
            brace_depth += 1
            found_brace = True
        elif ch == '}':
            brace_depth -= 1

        tok.pos += 1

    if found_brace:
        return brace_depth == 0
    return True


def extract_properties(body):
    """Extract top-level property declarations from the struct body."""
    if not body:
        return []

    properties = []
    lines = body.split('\n')
    idx = 0

    while idx < len(lines):
        line = lines[idx]
        stripped = line.strip()

        if not stripped or stripped.startswith('//'):
            idx += 1
            continue

        prop_match = re.match(r'\s+(let|var)\s+', line)
        if not prop_match:
            idx += 1
            continue

        # Collect lines until the property is complete
        prop_lines = [line]
        while not is_property_complete('\n'.join(prop_lines)):
            idx += 1
            if idx >= len(lines):
                break
            prop_lines.append(lines[idx])

        properties.append('\n'.join(prop_lines))
        idx += 1

    return properties


def make_static(prop_text):
    """Convert a property declaration to a static property."""
    lines = prop_text.split('\n')
    first_line = lines[0]
    modified = re.sub(r'^(\s+)(let|var)\s+', r'\1static \2 ', first_line, count=1)
    if len(lines) == 1:
        return modified
    return modified + '\n' + '\n'.join(lines[1:])


def insert_properties_into_rule(rule_content, static_props, config_struct_name):
    """Insert static properties into the Rule struct and remove the configuration line."""
    pattern = re.compile(
        r'\n?\s*static\s+let\s+configuration\s*=\s*' + re.escape(config_struct_name) + r'\(\)\s*\n',
    )
    rule_content = pattern.sub('\n', rule_content)

    struct_match = re.search(r'(struct\s+\w+[^{]*\{)\s*\n', rule_content)
    if not struct_match:
        return None

    insert_point = struct_match.end()
    props_block = '\n'.join(static_props) + '\n'
    new_content = rule_content[:insert_point] + props_block + rule_content[insert_point:]
    return new_content


def process_file(config_path, dry_run=False):
    rule_path = find_rule_file(config_path)
    if not rule_path:
        print(f"  SKIP (no rule file): {os.path.basename(config_path)}")
        return False

    with open(config_path, 'r') as f:
        config_content = f.read()

    struct_name, body = find_struct_body(config_content)
    if body is None:
        print(f"  SKIP (no struct body): {os.path.basename(config_path)}")
        return False

    properties = extract_properties(body)
    if not properties:
        print(f"  SKIP (no properties): {os.path.basename(config_path)}")
        return False

    static_props = [make_static(p) for p in properties]

    with open(rule_path, 'r') as f:
        rule_content = f.read()

    new_rule_content = insert_properties_into_rule(rule_content, static_props, struct_name)
    if new_rule_content is None:
        print(f"  SKIP (can't find struct): {os.path.basename(config_path)} -> {os.path.basename(rule_path)}")
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
