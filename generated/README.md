# generated/

Auto-generated pacscript skeletons produced by `scripts/kport/generate-pacscripts.sh`.

These are **not production-ready**. Each file needs human review before promotion
to `packages/`. Common things to verify:

- Build dependencies are complete and correctly named
- `source` URL resolves and the checksum is correct
- `build()` function produces a working install
- USE flag conditionals are correct for this package
- Slot handling is correct if multiple versions coexist
- Patches from `debian/patches/` are applied where needed

## Promotion workflow

1. Test the generated pacscript: `pacstall -Il generated/<category>/<pkg>/<pkg>.pacscript`
2. Fix any issues
3. Move to `packages/<category>/<pkg>/`
4. Open a PR — CI will validate the pacscript format and run a test build

## Regeneration

Generated files are overwritten on each generator run. Do not hand-edit files
in `generated/` — edit the promoted copy in `packages/` instead.
