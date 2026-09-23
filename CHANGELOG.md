# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.5.0] - 2026-09-23

### Added
- Added `StringPattern.with` to apply configuration for the duration of a block, and `StringPattern.reset!` to restore defaults and clear caches.
- Added `StringPattern::VERSION`.
- Added full-string `Regexp` validation via `StringPattern.validate`, `StringPattern.valid?`, and `Regexp#validate` / `#val`.
- Added `StringPattern.explain` with the failing segment index for pattern arrays.
- Added `StringPattern.iban` / `valid_iban?` (ISO 13616) and `StringPattern.luhn` / `valid_luhn?`.
- Added `block_list_regexp` to opt into the previous regular-expression block list.
- `StringPattern.sample` forwards `seed:` and other generate options.

### Changed
- Generation uses its own `Random` instance. `seed:` no longer calls `srand`, so it does not change `Kernel#rand`. Sequences for a given seed may differ from 2.4.0.
- `block_list` matches literals (case-insensitive) unless `block_list_regexp` is true.
- Spanish word generation loads all `data/spanish/palabras*.json` files instead of one random file.
- Invalid patterns and impossible generation honor `raise_on_error` on every failure path.
- Required Ruby version is 3.0 or newer.

## [2.4.0] - 2026-02-11

### Added
- Added `StringPattern.valid_email?` helper and centralized email format checks.
- Added `StringPattern.valid?(text:, pattern:)` for boolean validation.
- Added `StringPattern.sample(pattern, n)` for batch generation of distinct values.
- Added `StringPattern.uuid` and `StringPattern.valid_uuid?`.
- Added support for `seed:` in generation for reproducible outputs.
- Added support for `block_list` as a `Proc`.
- Added `StringPattern::InvalidPatternError` and `StringPattern::GenerationImpossibleError`.
- Added `StringPattern.logger` and `StringPattern.raise_on_error` configuration.
- Added `spec/string/pattern/analyze_spec.rb`.
- Added GitHub Actions CI workflow.

### Changed
- Fixed email-domain comparison bug in email validation/generation paths.
- Replaced internal direct `puts` calls with centralized logging (`StringPattern.log_message`).
- Updated README with analyze/validation/error-handling/new-features documentation.
- Updated CI target Ruby versions (3.0, 3.1, 3.2, 3.3).

## [2.3.0] - 2025-xx-xx

### Changed
- Previous release notes not yet backfilled.
