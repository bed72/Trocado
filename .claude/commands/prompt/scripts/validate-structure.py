#!/usr/bin/env python3
"""
Valida se um prompt estruturado contém os blocos XML obrigatórios e suas subcategorias.
Uso: python3 scripts/validate-structure.py < arquivo.md
"""
import re
import sys

REQUIRED_TAGS = ["<task>", "<goals>", "<role>", "<requirements>", "<critical>"]

REQUIREMENTS_SUBCATEGORIES = ["### Business", "### Technical", "### UI/UX"]
CRITICAL_SUBCATEGORIES = ["### Skills obrigatórias", "### Fora do Escopo"]

CONDITIONAL_RULES = [
    ("<endpoints>", "<tests>", "endpoints present but <tests> is missing"),
]


def extract_block(content: str, tag: str) -> str:
    """Extracts content between opening and closing XML tag."""
    name = tag.strip("<>")
    pattern = rf"<{name}>(.*?)</{name}>"
    match = re.search(pattern, content, re.DOTALL)
    return match.group(1) if match else ""


def main():
    content = sys.stdin.read()
    errors = []
    warnings = []

    # 1. Required top-level tags
    for tag in REQUIRED_TAGS:
        if tag not in content:
            errors.append(f"MISSING required block: {tag}")

    # 2. <requirements> must have all three subcategories
    requirements_block = extract_block(content, "<requirements>")
    if requirements_block:
        for sub in REQUIREMENTS_SUBCATEGORIES:
            if sub not in requirements_block:
                errors.append(f"MISSING subcategory in <requirements>: {sub}")
    elif "<requirements>" in content:
        for sub in REQUIREMENTS_SUBCATEGORIES:
            errors.append(f"MISSING subcategory in <requirements>: {sub}")

    # 3. <critical> must have both subcategories
    critical_block = extract_block(content, "<critical>")
    if critical_block:
        for sub in CRITICAL_SUBCATEGORIES:
            if sub not in critical_block:
                errors.append(f"MISSING subcategory in <critical>: {sub}")
    elif "<critical>" in content:
        for sub in CRITICAL_SUBCATEGORIES:
            errors.append(f"MISSING subcategory in <critical>: {sub}")

    # 4. Conditional rules (warnings, not errors)
    for trigger_tag, dependent_tag, message in CONDITIONAL_RULES:
        if trigger_tag in content and dependent_tag not in content:
            warnings.append(f"WARNING: {message}")

    if warnings:
        for warning in warnings:
            print(warning, file=sys.stderr)

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        sys.exit(1)

    print("SUCCESS: All required blocks and subcategories present.")
    sys.exit(0)


if __name__ == "__main__":
    main()
