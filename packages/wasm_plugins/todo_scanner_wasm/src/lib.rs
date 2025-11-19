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

use application::{ScanTodosUseCase, ScanRequest, ScanResponse};
use infrastructure::{RegexTodoScanner, memory};

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
        capabilities.insert("scan_speed".to_string(), "fast".to_string());
        capabilities.insert("max_file_size".to_string(), "10MB".to_string());
        capabilities.insert("supported_markers".to_string(), "TODO, FIXME, HACK, NOTE, XXX, BUG, OPTIMIZE, REVIEW".to_string());
        capabilities.insert("features".to_string(), "author extraction, tag extraction, priority detection".to_string());

        Self {
            id: "wasm.todo-scanner".to_string(),
            name: "TODO Scanner (WASM)".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
            description: "Fast TODO/FIXME/HACK scanner for large files using Rust WASM".to_string(),
            author: "Multi Editor Team".to_string(),
            supported_events: vec![
                "scan_todos".to_string(),
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
        "message": "TODO Scanner plugin initialized successfully",
        "scanner": "regex-based",
        "performance": "optimized for large files"
    });

    memory::serialize_and_pack(&response)
}

/// Handle plugin event
#[no_mangle]
pub extern "C" fn plugin_handle_event(event_ptr: u32, event_len: u32) -> u64 {
    // BUG FIX #11: Validate event_len before unsafe memory read
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
        "scan_todos" => handle_scan_todos(event.data),
        "get_capabilities" => handle_get_capabilities(),
        _ => error_response("unknown", &format!("Unknown event type: {}", event.event_type)),
    }
}

/// Dispose plugin
#[no_mangle]
pub extern "C" fn plugin_dispose() -> u64 {
    let response = serde_json::json!({
        "success": true,
        "message": "TODO Scanner plugin disposed successfully"
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

/// Handle scan_todos event
fn handle_scan_todos(data: HashMap<String, serde_json::Value>) -> u64 {
    // Parse request
    let request: ScanRequest = match serde_json::from_value(serde_json::Value::Object(
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
    // 1. Create dependencies (Infrastructure layer)
    let scanner = RegexTodoScanner::new();

    // 2. Create use case with injected dependency (Application layer)
    let use_case = ScanTodosUseCase::new(scanner);

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
            "scan_speed": "fast (regex-based)",
            "max_file_size": "10MB",
            "supported_markers": ["TODO", "FIXME", "HACK", "NOTE", "XXX", "BUG", "OPTIMIZE", "REVIEW"],
            "features": [
                "author extraction (TODO(john): ...)",
                "tag extraction (TODO #bug #critical: ...)",
                "priority detection (TODO !!! urgent: ...)"
            ],
            "typical_scan_time_10k_lines_ms": "5-20"
        }
    });

    memory::serialize_and_pack(&capabilities)
}

/// Create error response
fn error_response(request_id: &str, error_message: &str) -> u64 {
    let response = ScanResponse::error(
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
        assert_eq!(manifest.id, "wasm.todo-scanner");
        assert!(!manifest.supported_events.is_empty());
        assert!(manifest.capabilities.contains_key("scan_speed"));
    }

    #[test]
    fn test_full_scan_workflow() {
        let scanner = RegexTodoScanner::new();
        let use_case = ScanTodosUseCase::new(scanner);

        let request = ScanRequest::new(
            "test-1".to_string(),
            r#"
// TODO: implement feature X
// FIXME(john): fix the memory leak #bug #critical
// HACK: temporary solution
// NOTE: this is important
            "#.to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        assert!(response.data.is_some());

        let data = response.data.unwrap();
        assert_eq!(data.items.len(), 4);
        assert_eq!(data.counts_by_type.total(), 4);

        // Check author extraction
        let fixme_item = data.items.iter()
            .find(|item| matches!(item.todo_type, domain::TodoType::Fixme))
            .unwrap();
        assert_eq!(fixme_item.author, Some("john".to_string()));
        assert_eq!(fixme_item.tags, vec!["bug", "critical"]);
    }
}
