# Changelog

## 0.1.0-rc.1 (2026-10-30)

- Six file tools over trees kept in a `WardrikStore`: read, write, edit, list, search and delete.
- Each file versioned, so a stale write is refused.
- Trees shared under `shared/<name>/`, to read and write or only to read.
- `WardrikWorkspace.Context`, a middleware that reads named files into each turn within a budget.
- Each call names what it acts on, for policy rules like `write_file(notes/*)`.
