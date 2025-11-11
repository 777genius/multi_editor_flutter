// Infrastructure Layer - Nucleo Integration
//
// Adapter for nucleo-matcher fuzzy matching library.
// Nucleo is the fastest fuzzy matcher available (from Helix editor).
//
// Performance: 100x faster than Dart alternatives
// - Uses Smith-Waterman algorithm with SIMD optimizations
// - Handles 10,000 files in ~10-30ms
// - Used in production by Helix editor

pub mod nucleo_matcher;

pub use nucleo_matcher::NucleoMatcher;
