// Presentation Layer - WASM Exports
//
// Plugin entry points for host communication.
// Follow Clean Architecture: this layer knows about all other layers,
// but other layers don't know about this one.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// Import layers (Dependency Inversion - depend on abstractions)
mod domain;
mod application;
mod infrastructure;

use application::{RenderMarkdownUseCase, RenderRequest, RenderResponse};
use infrastructure::{PulldownRenderer, memory};

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
        capabilities.insert("markdown_rendering".to_string(), "full".to_string());
        capabilities.insert("github_flavored_markdown".to_string(), "true".to_string());
        capabilities.insert("syntax_highlighting".to_string(), "true".to_string());
        capabilities.insert("tables".to_string(), "true".to_string());
        capabilities.insert("task_lists".to_string(), "true".to_string());

        Self {
            id: "plugin.markdown-renderer-wasm".to_string(),
            name: "Markdown Renderer".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
            description: "Production-grade Markdown to HTML renderer using pulldown-cmark".to_string(),
            author: "Flutter Plugin System".to_string(),
            supported_events: vec![
                "render_markdown".to_string(),
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
        "message": "Markdown renderer initialized successfully"
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
        "render_markdown" => handle_render_markdown(event.data),
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
        "message": "Markdown renderer disposed successfully"
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

/// Handle render_markdown event
fn handle_render_markdown(data: HashMap<String, serde_json::Value>) -> u64 {
    // Extract request parameters
    let request_id = data
        .get("request_id")
        .and_then(|v| v.as_str())
        .unwrap_or("unknown")
        .to_string();

    let markdown = match data.get("markdown").and_then(|v| v.as_str()) {
        Some(md) => md.to_string(),
        None => {
            return error_response("Missing 'markdown' field");
        }
    };

    // Parse options (optional)
    let request = if let Some(options_value) = data.get("options") {
        match serde_json::from_value(options_value.clone()) {
            Ok(options) => RenderRequest::with_options(request_id, markdown, options),
            Err(_) => RenderRequest::new(request_id, markdown),
        }
    } else {
        RenderRequest::new(request_id, markdown)
    };

    // Execute use case
    // Create dependencies (Infrastructure layer)
    let renderer = PulldownRenderer::new();

    // Create use case (Application layer)
    let use_case = RenderMarkdownUseCase::new(renderer);

    // Execute
    let response = use_case.execute(request);

    // Serialize response
    memory::serialize_and_pack(&response)
}

/// Handle get_capabilities event
fn handle_get_capabilities() -> u64 {
    let capabilities = serde_json::json!({
        "success": true,
        "capabilities": {
            "markdown_rendering": "full",
            "github_flavored_markdown": true,
            "syntax_highlighting": true,
            "tables": true,
            "strikethrough": true,
            "task_lists": true,
            "footnotes": true,
            "heading_attributes": true,
            "max_input_size_mb": 10,
        }
    });

    memory::serialize_and_pack(&capabilities)
}

/// Create error response
fn error_response(error_message: &str) -> u64 {
    let response = RenderResponse::error(
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
        assert_eq!(manifest.id, "plugin.markdown-renderer-wasm");
        assert!(!manifest.supported_events.is_empty());
    }

    #[test]
    fn test_render_request_creation() {
        let request = RenderRequest::new(
            "test-1".to_string(),
            "# Hello".to_string(),
        );

        assert_eq!(request.request_id, "test-1");
    }
}
