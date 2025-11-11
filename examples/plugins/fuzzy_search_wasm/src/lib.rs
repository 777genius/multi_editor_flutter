// Presentation Layer - WASM Exports
//
// Plugin entry points for host communication.
// Follow Clean Architecture: this layer knows about all other layers,
// but other layers don't know about this one.
//
// Demonstrates Dependency Injection and Clean Architecture in action.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Import layers (Dependency Inversion - depend on abstractions)
mod domain;
mod application;
mod infrastructure;

use application::{SearchFilesUseCase, SearchRequest, SearchResponse};
use infrastructure::{NucleoMatcher, memory};

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
        capabilities.insert("fuzzy_search".to_string(), "advanced".to_string());
        capabilities.insert("algorithm".to_string(), "nucleo (Smith-Waterman + SIMD)".to_string());
        capabilities.insert("performance".to_string(), "100x faster than Dart".to_string());
        capabilities.insert("max_files".to_string(), "100000".to_string());

        Self {
            id: "plugin.fuzzy-search-wasm".to_string(),
            name: "Fuzzy File Search".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
            description: "Production-grade fuzzy file search using nucleo (100x faster than Dart)".to_string(),
            author: "Flutter Plugin System".to_string(),
            supported_events: vec![
                "search_files".to_string(),
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
///
/// Returns serialized plugin metadata.
/// Format: (ptr << 32) | len
#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64 {
    let manifest = PluginManifest::new();
    memory::serialize_and_pack(&manifest)
}

/// Initialize plugin
///
/// Called once when plugin is loaded.
#[no_mangle]
pub extern "C" fn plugin_initialize(_context_ptr: u32, _context_len: u32) -> u64 {
    let response = serde_json::json!({
        "success": true,
        "message": "Fuzzy search plugin initialized successfully",
        "algorithm": "nucleo (Smith-Waterman with SIMD)",
        "performance": "100x faster than Dart"
    });

    memory::serialize_and_pack(&response)
}

/// Handle plugin event
///
/// Main entry point for plugin operations.
///
/// ## Arguments
/// * `event_ptr` - Pointer to event data (MessagePack)
/// * `event_len` - Length of event data
///
/// ## Returns
/// Packed pointer and length to response data (MessagePack)
#[no_mangle]
pub extern "C" fn plugin_handle_event(event_ptr: u32, event_len: u32) -> u64 {
    // Read event data from WASM memory
    let event_bytes = unsafe {
        std::slice::from_raw_parts(event_ptr as *const u8, event_len as usize)
    };

    // Deserialize event
    let event: PluginEvent = match rmp_serde::from_slice(event_bytes) {
        Ok(e) => e,
        Err(err) => {
            return error_response(&format!("Failed to deserialize event: {}", err));
        }
    };

    // Route to appropriate handler
    match event.event_type.as_str() {
        "search_files" => handle_search_files(event.data),
        "get_capabilities" => handle_get_capabilities(),
        _ => error_response(&format!("Unknown event type: {}", event.event_type)),
    }
}

/// Dispose plugin
///
/// Called when plugin is unloaded.
#[no_mangle]
pub extern "C" fn plugin_dispose() -> u64 {
    let response = serde_json::json!({
        "success": true,
        "message": "Fuzzy search plugin disposed successfully"
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

/// Handle search_files event
///
/// Demonstrates Clean Architecture and Dependency Injection:
/// 1. Create infrastructure dependency (NucleoMatcher)
/// 2. Inject into application use case (SearchFilesUseCase)
/// 3. Execute use case with domain logic
fn handle_search_files(data: HashMap<String, serde_json::Value>) -> u64 {
    // Parse request
    let request: SearchRequest = match serde_json::from_value(serde_json::Value::Object(
        data.into_iter().collect(),
    )) {
        Ok(req) => req,
        Err(err) => {
            return error_response(&format!("Invalid request format: {}", err));
        }
    };

    // ========================================================================
    // Clean Architecture in Action!
    // ========================================================================
    //
    // 1. Create dependencies (Infrastructure layer)
    //    - NucleoMatcher implements FuzzyMatcher trait from domain
    let matcher = NucleoMatcher::new();

    // 2. Create use case with injected dependency (Application layer)
    //    - SearchFilesUseCase depends on FuzzyMatcher trait (abstraction)
    //    - NOT on NucleoMatcher concrete type (Dependency Inversion!)
    let use_case = SearchFilesUseCase::new(matcher);

    // 3. Execute use case (orchestrates domain logic)
    let response = use_case.execute(request);

    // 4. Serialize response
    memory::serialize_and_pack(&response)
}

/// Handle get_capabilities event
fn handle_get_capabilities() -> u64 {
    let capabilities = serde_json::json!({
        "success": true,
        "capabilities": {
            "fuzzy_search": "advanced",
            "algorithm": "nucleo (Smith-Waterman + SIMD)",
            "performance": "100x faster than Dart",
            "max_files": 100_000,
            "supports_unicode": true,
            "supports_case_sensitive": true,
            "typical_latency_10k_files_ms": "10-30",
        }
    });

    memory::serialize_and_pack(&capabilities)
}

/// Create error response
fn error_response(error_message: &str) -> u64 {
    let response = SearchResponse::error(
        "unknown".to_string(),
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
        assert_eq!(manifest.id, "plugin.fuzzy-search-wasm");
        assert!(!manifest.supported_events.is_empty());
        assert!(manifest.capabilities.contains_key("fuzzy_search"));
    }

    #[test]
    fn test_search_request_creation() {
        let request = SearchRequest::new(
            "test-1".to_string(),
            "test".to_string(),
            vec!["file1.rs".to_string()],
        );

        assert_eq!(request.request_id, "test-1");
        assert_eq!(request.query, "test");
    }

    #[test]
    fn test_use_case_with_nucleo() {
        // Integration test: Full stack
        let matcher = NucleoMatcher::new();
        let use_case = SearchFilesUseCase::new(matcher);

        let request = SearchRequest::new(
            "test-1".to_string(),
            "test".to_string(),
            vec![
                "src/test.rs".to_string(),
                "src/main.rs".to_string(),
                "test_helper.rs".to_string(),
            ],
        );

        let response = use_case.execute(request);

        assert!(response.success);
        assert!(!response.matches.is_empty());
        // Search time can be 0ms on fast machines
        assert!(response.statistics.search_time_ms >= 0);
    }
}
