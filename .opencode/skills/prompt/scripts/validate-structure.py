#!/usr/bin/env python3
"""Validate required XML blocks in a structured prompt."""

import re
import sys

REQUIRED_TAGS = ["<task>", "<goals>", "<role>", "<requirements>", "<critical>"]
REQUIREMENTS_SUBCATEGORIES = ["### Business", "### Technical", "### UI/UX"]
CRITICAL_SUBCATEGORIES = ["### Skills obrigatórias", "### Fora do Escopo"]


def extract_block(content: str, tag: str) -> str:
    name = tag.strip("<>")
    match = re.search(rf"<{name}>(.*?)</{name}>", content, re.DOTALL)
    return match.group(1) if match else ""


def main() -> None:
    content = sys.stdin.read()
    errors = []

    for tag in REQUIRED_TAGS:
        if tag not in content:
            errors.append(f"MISSING required block: {tag}")

    requirements = extract_block(content, "<requirements>")
    for subcategory in REQUIREMENTS_SUBCATEGORIES:
        if subcategory not in requirements:
            errors.append(f"MISSING subcategory in <requirements>: {subcategory}")

    critical = extract_block(content, "<critical>")
    for subcategory in CRITICAL_SUBCATEGORIES:
        if subcategory not in critical:
            errors.append(f"MISSING subcategory in <critical>: {subcategory}")

    if "<endpoints>" in content and "<tests>" not in content:
        print("WARNING: endpoints present but <tests> is missing", file=sys.stderr)

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        raise SystemExit(1)

    print("SUCCESS: All required blocks and subcategories present.")


if __name__ == "__main__":
    main()
