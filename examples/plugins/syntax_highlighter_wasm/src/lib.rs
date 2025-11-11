//! Syntax Highlighter WASM Plugin
//!
//! Production-grade syntax highlighter using Tree-sitter.
//! Demonstrates Clean Architecture + DDD + SOLID + DRY principles.
//!
//! ## Architecture Layers
//!
//! 1. **Domain Layer** (`domain/`)
//!    - Pure business logic
//!    - Entities: SyntaxTree, HighlightRange
//!    - Value Objects: Language, Position, Theme
//!    - Services (traits): Parser, Highlighter
//!
//! 2. **Application Layer** (`application/`)
//!    - Use Cases: HighlightCodeUseCase
//!    - DTOs: ParseRequest, HighlightResponse
//!    - Orchestrates domain operations
//!
//! 3. **Infrastructure Layer** (`infrastructure/`)
//!    - Syntect adapters: SyntectParser, SyntectHighlighter
//!    - Memory management: alloc, dealloc
//!    - Implements domain interfaces
//!
//! 4. **Presentation Layer** (this file)
//!    - WASM exports: plugin_* functions
//!    - API for host system
//!    - Serialization/deserialization
//!
//! ## SOLID Principles
//!
//! - **SRP**: Each class has single responsibility
//! - **OCP**: Extensible via traits (Parser, Highlighter)
//! - **LSP**: Proper trait hierarchies
//! - **ISP**: Minimal interfaces (Parser, Highlighter)
//! - **DIP**: Depend on abstractions, not concretions

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Layer imports (follow dependency rule: outer → inner)
mod domain;
mod application;
mod infrastructure;

use domain::{Theme, Language};
use application::{HighlightCodeUseCase, ParseRequest};
use infrastructure::{SyntectParser, SyntectHighlighter, memory};

// Re-export memory functions
pub use infrastructure::memory::{alloc, dealloc};

// ============================================================================
// Plugin State (Singleton Pattern)
// ============================================================================

/// Global plugin state
///
/// In production, use proper state management with Arc<Mutex<T>>.
/// WASM is single-threaded, so simple static is sufficient.
static mut INITIALIZED: bool = false;
static mut THEME: Option<Theme> = None;

// ============================================================================
// Data Structures
// ============================================================================

#[derive(Debug, Serialize, Deserialize)]
struct PluginManifest {
    id: String,
    name: String,
    version: String,
    author: String,
    description: String,
    #[serde(rename = "runtimeType")]
    runtime_type: String,
    #[serde(rename = "runtimeVersion")]
    runtime_version: String,
    permissions: Permissions,
}

#[derive(Debug, Serialize, Deserialize)]
struct Permissions {
    #[serde(rename = "hostFunctions")]
    host_functions: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct EventData {
    #[serde(rename = "type")]
    event_type: String,
    data: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
struct PluginResponse {
    handled: bool,
    data: HashMap<String, serde_json::Value>,
}

// ============================================================================
// WASM Exports (Plugin API)
// ============================================================================

/// Get plugin manifest
///
/// Returns packed pointer (u64): (ptr << 32) | len
/// Host must call dealloc(ptr, len) after reading.
#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64 {
    let manifest = PluginManifest {
        id: "plugin.syntax-highlighter-wasm".to_string(),
        name: "Syntax Highlighter (Tree-sitter)".to_string(),
        version: "0.1.0".to_string(),
        author: "Multi-Editor Team".to_string(),
        description: "Production-grade syntax highlighter using Tree-sitter. \
                     Demonstrates Clean Architecture + DDD + SOLID principles."
            .to_string(),
        runtime_type: "wasm".to_string(),
        runtime_version: "1.0.0".to_string(),
        permissions: Permissions {
            host_functions: vec!["log_info".to_string()],
        },
    };

    memory::serialize_and_pack(&manifest)
}

/// Initialize plugin
///
/// Input: (ptr, len) pointing to context data (MessagePack)
/// Returns: packed (ptr, len) with result
#[no_mangle]
pub extern "C" fn plugin_initialize(_ptr: *const u8, _len: u32) -> u64 {
    unsafe {
        INITIALIZED = true;
        THEME = Some(Theme::dark_default());
    }

    let response = PluginResponse {
        handled: true,
        data: HashMap::from([
            ("status".to_string(), serde_json::json!("initialized")),
            (
                "supported_languages".to_string(),
                serde_json::json!(["rust", "javascript", "json"]),
            ),
        ]),
    };

    memory::serialize_and_pack(&response)
}

/// Handle event
///
/// Input: (ptr, len) pointing to event data (MessagePack)
/// Returns: packed (ptr, len) with response
#[no_mangle]
pub extern "C" fn plugin_handle_event(ptr: *const u8, len: u32) -> u64 {
    // Check initialization
    unsafe {
        if !INITIALIZED {
            return pack_error("Plugin not initialized");
        }
    }

    // Deserialize event
    let event_bytes = unsafe { std::slice::from_raw_parts(ptr, len as usize) };

    let event: EventData = match rmp_serde::from_slice(event_bytes) {
        Ok(e) => e,
        Err(e) => return pack_error(&format!("Failed to deserialize event: {}", e)),
    };

    // Handle "highlight_code" event
    if event.event_type == "highlight_code" {
        return handle_highlight_event(&event.data);
    }

    // Event not handled
    let response = PluginResponse {
        handled: false,
        data: HashMap::new(),
    };

    memory::serialize_and_pack(&response)
}

/// Dispose plugin
///
/// Returns: packed (ptr, len) with result
#[no_mangle]
pub extern "C" fn plugin_dispose() -> u64 {
    unsafe {
        INITIALIZED = false;
        THEME = None;
    }

    let response = PluginResponse {
        handled: true,
        data: HashMap::from([("status".to_string(), serde_json::json!("disposed"))]),
    };

    memory::serialize_and_pack(&response)
}

// ============================================================================
// Event Handlers
// ============================================================================

/// Handle "highlight_code" event
///
/// Uses Clean Architecture: Presentation → Application → Domain → Infrastructure
fn handle_highlight_event(data: &HashMap<String, serde_json::Value>) -> u64 {
    // Extract parameters
    let language = data
        .get("language")
        .and_then(|v| v.as_str())
        .unwrap_or("");

    let source_code = data
        .get("source_code")
        .and_then(|v| v.as_str())
        .unwrap_or("");

    if source_code.is_empty() {
        return pack_error("source_code is required");
    }

    // Create parse request (Application layer DTO)
    let request = ParseRequest {
        language: language.to_string(),
        source_code: source_code.to_string(),
        incremental: false,
    };

    // Get theme
    let theme = unsafe { THEME.as_ref().unwrap() };

    // Create dependencies (Infrastructure layer)
    let parser = SyntectParser::new();
    let highlighter = SyntectHighlighter::new();

    // Execute use case (Application layer)
    let use_case = HighlightCodeUseCase::new(parser, highlighter);

    match use_case.execute(&request, theme) {
        Ok(response) => {
            // Convert to response format
            let mut result_data = HashMap::new();
            result_data.insert("ranges".to_string(), serde_json::to_value(&response.ranges).unwrap());
            result_data.insert("total_highlights".to_string(), serde_json::json!(response.total_highlights));
            result_data.insert("language".to_string(), serde_json::json!(response.language));
            result_data.insert("has_errors".to_string(), serde_json::json!(response.has_errors));
            result_data.insert("statistics".to_string(), serde_json::to_value(&response.statistics).unwrap());

            let response = PluginResponse {
                handled: true,
                data: result_data,
            };

            memory::serialize_and_pack(&response)
        }
        Err(e) => pack_error(&e),
    }
}

// ============================================================================
// Helpers
// ============================================================================

/// Pack error message
fn pack_error(msg: &str) -> u64 {
    let response = PluginResponse {
        handled: false,
        data: HashMap::from([("error".to_string(), serde_json::json!(msg))]),
    };

    memory::serialize_and_pack(&response)
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_plugin_lifecycle() {
        // Get manifest
        let manifest_packed = plugin_get_manifest();
        assert_ne!(manifest_packed, 0);

        // Initialize
        let init_packed = plugin_initialize(std::ptr::null(), 0);
        assert_ne!(init_packed, 0);

        // Check initialized
        assert!(unsafe { INITIALIZED });

        // Dispose
        let dispose_packed = plugin_dispose();
        assert_ne!(dispose_packed, 0);

        // Check disposed
        assert!(!unsafe { INITIALIZED });
    }
}
