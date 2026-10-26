# Changelog

## 0.1.0 (unreleased)

- Six file tools over trees kept in a `WardrikStore`, each file versioned, so a stale write is
  refused.
- Trees shared under `shared/<name>/`, to read and write or only to read.
- `WardrikWorkspace.Context`, a middleware that reads named files into each turn within a budget.
- Each call names what it acts on, for policy rules like `write_file(notes/*)`.
