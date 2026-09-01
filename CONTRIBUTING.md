# Project Conventions

## Commits

This project uses [scoped commits](https://scopedcommits.com/) to better
distinguish what parts of the project a commit touches.

## Changelog

This project has one changelog for each published package. Make sure to update
the changelog accordingly for user-visible changes. Describe in the change log
line whether the change is breaking or not.

## Releases

When cutting a new release:

1. Make a new heading in the changelog with the release date.
2. Move everything in `[Unreleased]` under the new heading for the released
   version.
3. Bump the version number in the package's `package.nix`.
4. Run `nix-hpack` to update the `.cabal` file.

## Proposals

> These conventions are mostly useful for bigger tasks. Small fixes and minor
> changes don't need to follow this structure.

Proposals live under `<component>/proposals/` (e.g. `tricorder/proposals/`).

Each proposal is a folder named `NNN-short-title/` where `NNN` is a zero-padded
ascending integer. Lower numbers are older; higher numbers are newer. A template is
provided at `000-template/`.

### Files within a proposal

| File          | Purpose                                                                                       |
| ------------- | --------------------------------------------------------------------------------------------- |
| `README.md`   | Work package — high-level description, objectives, milestones, acceptance criteria            |
| `design.md`   | Design — problem statement, chosen approach, alternatives considered, trade-offs              |
| `spec.md`     | Spec — precise contracts, wire formats, type definitions; the reference during implementation |
| `research.md` | Research — time-boxed explorations and findings that informed the design                      |

Not every proposal needs all four files. A simple refactor may only need `README.md`.
Create the others when the work warrants it.

### Proposal index

Each `proposals/` directory has a `README.md` index listing all proposals with their
status. Keep it up to date when adding or completing proposals.
