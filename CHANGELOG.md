# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
