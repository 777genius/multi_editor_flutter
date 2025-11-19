// Presentation Layer - WASM Exports
//
// Plugin entry points for host communication.
// Follow Clean Architecture: this layer knows about all other layers.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Import layers
mod domain;
mod application;
mod infrastructure;

use application::{AnalyzeBracketsUseCase, AnalyzeRequest, AnalyzeResponse};
use domain::{StackBasedMatcher, ColorScheme};
use infrastructure::memory;

// Re-export allocator functions
pub use infrastructure::{alloc, dealloc};

// ============================================================================
// Plugin Manifest
// ============================================================================

/// Plugin Manifest
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginManifest {
    pub id: String,
    pub name: String,
    pub version: String,
    pub description: String,
    pub author: String,
    pub supported_events: Vec<String>,
    pub capabilities: HashMap<String, String>,
}

impl PluginManifest {
    fn new() -> Self {
        let mut capabilities = HashMap::new();
        capabilities.insert("bracket_types".to_string(), "(), {}, [], <>".to_string());
        capabilities.insert("max_depth".to_string(), "unlimited".to_string());
        capabilities.insert("color_schemes".to_string(), "rainbow, monochrome, custom".to_string());
        capabilities.insert("features".to_string(), "nesting depth, color cycling, error detection, string/comment aware".to_string());
        capabilities.insert("performance".to_string(), "optimized stack-based algorithm".to_string());

        Self {
            id: "wasm.bracket-colorizer".to_string(),
            name: "Bracket Pair Colorizer (WASM)".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
            description: "Rainbow bracket colorizer with nesting depth analysis and error detection".to_string(),
            author: "Multi Editor Team".to_string(),
            supported_events: vec![
                "analyze_brackets".to_string(),
                "get_color_at_position".to_string(),
                "get_capabilities".to_string(),
            ],
            capabilities,
        }
    }
}

// ============================================================================
// Plugin Lifecycle
// ============================================================================

/// Get plugin manifest
#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64 {
    let manifest = PluginManifest::new();
    memory::serialize_and_pack(&manifest)
}

/// Initialize plugin
#[no_mangle]
pub extern "C" fn plugin_initialize(_context_ptr: u32, _context_len: u32) -> u64 {
    let response = serde_json::json!({
        "success": true,
        "message": "Bracket Colorizer plugin initialized successfully",
        "algorithm": "stack-based bracket matching",
        "features": [
            "Rainbow colors",
            "Nesting depth tracking",
            "Error detection (unmatched, mismatched)",
            "String/comment awareness",
            "Language-specific handling"
        ]
    });

    memory::serialize_and_pack(&response)
}

/// Handle plugin event
#[no_mangle]
pub extern "C" fn plugin_handle_event(event_ptr: u32, event_len: u32) -> u64 {
    // BUG FIX #11: Validate event_len before unsafe memory read
    // Prevent reading invalid memory or OOM attacks
    const MAX_EVENT_SIZE: u32 = 10 * 1024 * 1024; // 10MB max

    if event_len == 0 {
        return error_response("unknown", "Empty event data");
    }

    if event_len > MAX_EVENT_SIZE {
        return error_response("unknown", &format!("Event too large: {} bytes (max {})", event_len, MAX_EVENT_SIZE));
    }

    // Read event data from WASM memory
    let event_bytes = unsafe {
        std::slice::from_raw_parts(event_ptr as *const u8, event_len as usize)
    };

    // Deserialize event
    let event: PluginEvent = match rmp_serde::from_slice(event_bytes) {
        Ok(e) => e,
        Err(err) => {
            return error_response("unknown", &format!("Failed to deserialize event: {}", err));
        }
    };

    // Route to appropriate handler
    match event.event_type.as_str() {
        "analyze_brackets" => handle_analyze_brackets(event.data),
        "get_capabilities" => handle_get_capabilities(),
        _ => error_response("unknown", &format!("Unknown event type: {}", event.event_type)),
    }
}

/// Dispose plugin
#[no_mangle]
pub extern "C" fn plugin_dispose() -> u64 {
    let response = serde_json::json!({
        "success": true,
        "message": "Bracket Colorizer plugin disposed successfully"
    });

    memory::serialize_and_pack(&response)
}

// ============================================================================
// Event Handlers
// ============================================================================

/// Plugin Event
#[derive(Debug, Deserialize)]
struct PluginEvent {
    event_type: String,
    data: HashMap<String, serde_json::Value>,
}

/// Handle analyze_brackets event
fn handle_analyze_brackets(data: HashMap<String, serde_json::Value>) -> u64 {
    // Parse request
    let request: AnalyzeRequest = match serde_json::from_value(serde_json::Value::Object(
        data.into_iter().collect(),
    )) {
        Ok(req) => req,
        Err(err) => {
            return error_response("unknown", &format!("Invalid request format: {}", err));
        }
    };

    let request_id = request.request_id.clone();

    // ========================================================================
    // Clean Architecture in Action!
    // ========================================================================
    //
    // 1. Get color scheme from request or use default
    let color_scheme = request.get_color_scheme();

    // 2. Create dependencies (Infrastructure layer)
    let analyzer = StackBasedMatcher::new(color_scheme);

    // 3. Create use case with injected dependency (Application layer)
    let use_case = AnalyzeBracketsUseCase::new(analyzer);

    // 4. Execute use case (orchestrates domain logic)
    let response = use_case.execute(request);

    // 5. Serialize response
    memory::serialize_and_pack(&response)
}

/// Handle get_capabilities event
fn handle_get_capabilities() -> u64 {
    let capabilities = serde_json::json!({
        "success": true,
        "capabilities": {
            "bracket_types": ["()", "{}", "[]", "<>"],
            "max_depth": "unlimited",
            "color_schemes": {
                "rainbow": {
                    "colors": 6,
                    "default": ["#FFD700", "#DA70D6", "#179FFF", "#FF6347", "#3CB371", "#FF8C00"]
                },
                "monochrome": {
                    "colors": 1,
                    "customizable": true
                },
                "custom": {
                    "colors": "unlimited",
                    "format": "hex (#RRGGBB)"
                }
            },
            "features": [
                "Nesting depth tracking",
                "Color cycling based on depth",
                "Unmatched bracket detection",
                "Mismatched bracket detection",
                "String literal awareness",
                "Comment awareness (single-line //,  multi-line /* */)",
                "Language-specific handling (generics in Rust, C++, Java, etc.)"
            ],
            "performance": {
                "algorithm": "stack-based O(n)",
                "typical_time_10k_lines_ms": "10-30",
                "incremental_parsing": "planned"
            }
        }
    });

    memory::serialize_and_pack(&capabilities)
}

/// Create error response
fn error_response(request_id: &str, error_message: &str) -> u64 {
    let response = AnalyzeResponse::error(
        request_id.to_string(),
        error_message.to_string(),
    );

    memory::serialize_and_pack(&response)
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_manifest() {
        let manifest = PluginManifest::new();
        assert_eq!(manifest.id, "wasm.bracket-colorizer");
        assert!(!manifest.supported_events.is_empty());
        assert!(manifest.capabilities.contains_key("bracket_types"));
    }

    #[test]
    fn test_full_analysis_workflow() {
        let color_scheme = ColorScheme::default_rainbow();
        let analyzer = StackBasedMatcher::new(color_scheme);
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-1".to_string(),
            r#"
function test() {
    let arr = [1, 2, 3];
    if (arr.length) {
        console.log("Hello");
    }
}
            "#
            .to_string(),
        )
        .with_language("javascript".to_string());

        let response = use_case.execute(request);

        assert!(response.success);
        assert!(response.data.is_some());

        let data = response.data.unwrap();

        eprintln!("DEBUG test_full_analysis_workflow:");
        eprintln!("  Pairs: {}", data.pairs.len());
        eprintln!("  Unmatched: {}", data.unmatched.len());
        for (i, um) in data.unmatched.iter().enumerate() {
            eprintln!("    {}: {:?} at line {}, col {}", i, um.bracket.bracket_type, um.bracket.position.line, um.bracket.position.column);
        }

        assert!(data.pairs.len() > 0);
        assert_eq!(data.unmatched.len(), 0); // All brackets matched

        // Check statistics
        assert!(data.statistics.round_pairs > 0); // ()
        assert!(data.statistics.curly_pairs > 0); // {}
        assert!(data.statistics.square_pairs > 0); // []
    }

    #[test]
    fn test_nested_brackets_with_colors() {
        let color_scheme = ColorScheme::default_rainbow();
        let analyzer = StackBasedMatcher::new(color_scheme.clone());
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-2".to_string(),
            "{ [ ( ) ] }".to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();

        // Check depth assignment
        let curly_pair = data.pairs.iter().find(|p| p.bracket_type() == domain::BracketType::Curly).unwrap();
        let square_pair = data.pairs.iter().find(|p| p.bracket_type() == domain::BracketType::Square).unwrap();
        let round_pair = data.pairs.iter().find(|p| p.bracket_type() == domain::BracketType::Round).unwrap();

        assert_eq!(curly_pair.depth, 0);
        assert_eq!(square_pair.depth, 1);
        assert_eq!(round_pair.depth, 2);

        // Check color levels
        assert_eq!(curly_pair.color_level().value(), 0);
        assert_eq!(square_pair.color_level().value(), 1);
        assert_eq!(round_pair.color_level().value(), 2);
    }

    #[test]
    fn test_unmatched_brackets() {
        let color_scheme = ColorScheme::default_rainbow();
        let analyzer = StackBasedMatcher::new(color_scheme);
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-3".to_string(),
            "{ ( }".to_string(), // Missing closing )
        );

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();

        assert!(data.has_errors());
        assert!(data.unmatched.len() > 0);
    }

    #[test]
    fn test_brackets_in_strings() {
        let color_scheme = ColorScheme::default_rainbow();
        let analyzer = StackBasedMatcher::new(color_scheme);
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-4".to_string(),
            r#"let s = "{ not counted }"; { real }"#.to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();

        // Should only find the real {}, not the ones in string
        assert_eq!(data.pairs.len(), 1);
        assert_eq!(data.statistics.curly_pairs, 1);
    }

    #[test]
    fn test_brackets_in_comments() {
        let color_scheme = ColorScheme::default_rainbow();
        let analyzer = StackBasedMatcher::new(color_scheme);
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-5".to_string(),
            "{ // ( not counted\n }".to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();

        // Should only find the {}, not the ( in comment
        assert_eq!(data.pairs.len(), 1);
        assert_eq!(data.statistics.curly_pairs, 1);
    }
}
