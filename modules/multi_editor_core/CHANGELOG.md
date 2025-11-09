# Changelog

## [0.1.2] - 2025-11-09

### Fixed
- Fixed missing Freezed-generated files (.freezed.dart, .g.dart)
- Package now compiles correctly when installed from pub.dev
- All generated files are now included in published package

## [0.1.1] - 2025-01-08

### Fixed
- Updated repository URL to point to correct monorepo path
- Improved package metadata for better pub.dev scoring

### Changed
- Enhanced package documentation
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-08

### Added

- Initial release
- Domain layer with Clean Architecture and DDD principles
- Core entities: `FileDocument`, `FileTreeNode`, `FileMetadata`
- Value objects with validation and immutability
- Repository interfaces for data access abstraction
- Domain services for file operations
- Type-safe sealed classes using Freezed
- JSON serialization support
