#!/usr/bin/env python3
"""Create an offline endpoint inventory from a public OpenAPI JSON capture."""

import argparse
import json
from pathlib import Path
import sys


METHODS = {"get", "put", "post", "delete", "options", "head", "patch", "trace"}


def cell(value):
    return " ".join(str(value).split()).replace("|", r"\|").replace("`", "'")


def inventory(document):
    if not isinstance(document, dict):
        raise ValueError("Schema must be a JSON object.")
    version = document.get("openapi") or document.get("swagger")
    if not isinstance(version, str):
        raise ValueError("No OpenAPI or Swagger version found.")
    paths = document.get("paths")
    if not isinstance(paths, dict):
        raise ValueError("Schema must contain a paths object.")
    components = document.get("components", {})
    if not isinstance(components, dict):
        raise ValueError("components must be an object.")
    schemas = components.get("schemas", document.get("definitions", {}))
    if not isinstance(schemas, dict):
        raise ValueError("schemas/definitions must be an object.")
    rows = []
    references = 0
    for path, item in sorted(paths.items()):
        if not isinstance(item, dict):
            raise ValueError(f"Path item is not an object: {path}")
        references += int("$ref" in item)
        for method, operation in sorted(item.items()):
            if method not in METHODS:
                continue
            if not isinstance(operation, dict):
                raise ValueError(f"Operation is not an object: {method} {path}")
            rows.append((method.upper(), path, operation.get("summary", "")))
    info = document.get("info", {})
    title = info.get("title", "Public API") if isinstance(info, dict) else "Public API"
    lines = [
        f"# {cell(title)}: captured API inventory",
        "",
        f"Schema version: {cell(version)}",
        f"Paths: {len(paths)}; inline operations: {len(rows)}; schemas: {len(schemas)}.",
        "",
        "Counts describe this capture, not runtime behavior. References are not resolved.",
    ]
    if references:
        lines.append(f"Path items containing unresolved references: {references}.")
    lines.extend(["", "| Method | Path | Summary |", "|---|---|---|"])
    lines.extend(f"| {method} | {cell(path)} | {cell(summary)} |" for method, path, summary in rows)
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("schema", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        if args.output and args.output.resolve() == args.schema.resolve():
            raise ValueError("Output must not overwrite the input schema.")
        rendered = inventory(json.loads(args.schema.read_text(encoding="utf-8")))
        if args.output:
            args.output.write_text(rendered, encoding="utf-8")
            print(f"Saved inventory to {args.output}")
        else:
            print(rendered, end="")
    except (OSError, ValueError) as error:
        print(f"Inventory failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
