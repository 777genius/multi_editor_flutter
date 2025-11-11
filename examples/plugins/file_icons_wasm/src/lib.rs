use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// ============================================================================
// Memory Management (Linear Memory Pattern)
// ============================================================================

/// Allocate memory in WASM linear memory
///
/// Host calls this to allocate space for input data.
/// Returns pointer to allocated memory.
#[no_mangle]
pub extern "C" fn alloc(size: u32) -> *mut u8 {
    let mut buf = Vec::with_capacity(size as usize);
    let ptr = buf.as_mut_ptr();
    std::mem::forget(buf); // Prevent Rust from deallocating
    ptr
}

/// Deallocate memory in WASM linear memory
///
/// Host calls this to free memory after reading result.
/// Ownership model: allocator frees.
#[no_mangle]
pub extern "C" fn dealloc(ptr: *mut u8, size: u32) {
    unsafe {
        let _ = Vec::from_raw_parts(ptr, size as usize, size as usize);
        // Vec will be dropped and memory freed
    }
}

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
// Plugin State
// ============================================================================

static mut INITIALIZED: bool = false;

// File extension to icon mapping (Devicon style)
fn get_icon_map() -> HashMap<&'static str, &'static str> {
    let mut map = HashMap::new();

    // Programming languages
    map.insert("rs", "devicon-rust-plain");
    map.insert("dart", "devicon-dart-plain");
    map.insert("js", "devicon-javascript-plain");
    map.insert("ts", "devicon-typescript-plain");
    map.insert("py", "devicon-python-plain");
    map.insert("java", "devicon-java-plain");
    map.insert("go", "devicon-go-plain");
    map.insert("cpp", "devicon-cplusplus-plain");
    map.insert("c", "devicon-c-plain");
    map.insert("cs", "devicon-csharp-plain");

    // Markup/Config
    map.insert("html", "devicon-html5-plain");
    map.insert("css", "devicon-css3-plain");
    map.insert("json", "devicon-json-plain");
    map.insert("yaml", "devicon-yaml-plain");
    map.insert("yml", "devicon-yaml-plain");
    map.insert("toml", "devicon-toml-plain");
    map.insert("xml", "devicon-xml-plain");
    map.insert("md", "devicon-markdown-plain");

    // Build/Package
    map.insert("lock", "devicon-lock-plain");
    map.insert("gradle", "devicon-gradle-plain");
    map.insert("docker", "devicon-docker-plain");

    // Default
    map.insert("txt", "devicon-file-text");

    map
}

// ============================================================================
// Plugin API (exported to host)
// ============================================================================

/// Get plugin manifest
///
/// Returns packed pointer (u64): (ptr << 32) | len
/// Host must call dealloc(ptr, len) after reading.
#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64 {
    let manifest = PluginManifest {
        id: "plugin.file-icons-wasm".to_string(),
        name: "File Icons (WASM)".to_string(),
        version: "0.1.0".to_string(),
        author: "Multi-Editor Team".to_string(),
        description: "Provides file icons based on extension (Rust WASM example)".to_string(),
        runtime_type: "wasm".to_string(),
        runtime_version: "1.0.0".to_string(),
        permissions: Permissions {
            host_functions: vec!["log_info".to_string()],
        },
    };

    serialize_and_pack(&manifest)
}

/// Initialize plugin
///
/// Input: (ptr, len) pointing to context data (MessagePack)
/// Returns: packed (ptr, len) with result
#[no_mangle]
pub extern "C" fn plugin_initialize(ptr: *const u8, len: u32) -> u64 {
    let _context = unsafe {
        std::slice::from_raw_parts(ptr, len as usize)
    };

    // Mark as initialized
    unsafe {
        INITIALIZED = true;
    }

    let result = PluginResponse {
        handled: true,
        data: HashMap::from([
            ("status".to_string(), serde_json::json!("initialized")),
            ("icon_count".to_string(), serde_json::json!(get_icon_map().len())),
        ]),
    };

    serialize_and_pack(&result)
}

/// Handle event
///
/// Input: (ptr, len) pointing to event data (MessagePack)
/// Returns: packed (ptr, len) with response
#[no_mangle]
pub extern "C" fn plugin_handle_event(ptr: *const u8, len: u32) -> u64 {
    unsafe {
        if !INITIALIZED {
            return pack_error("Plugin not initialized");
        }
    }

    let event_bytes = unsafe {
        std::slice::from_raw_parts(ptr, len as usize)
    };

    let event: EventData = match rmp_serde::from_slice(event_bytes) {
        Ok(e) => e,
        Err(_) => return pack_error("Failed to deserialize event"),
    };

    // Handle "get_icon" event
    if event.event_type == "get_icon" {
        let extension = event.data.get("extension")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        let icon_map = get_icon_map();
        let icon = icon_map.get(extension)
            .or_else(|| icon_map.get("txt"))
            .unwrap_or(&"devicon-file");

        let response = PluginResponse {
            handled: true,
            data: HashMap::from([
                ("icon".to_string(), serde_json::json!(icon)),
                ("extension".to_string(), serde_json::json!(extension)),
            ]),
        };

        return serialize_and_pack(&response);
    }

    // Event not handled
    let response = PluginResponse {
        handled: false,
        data: HashMap::new(),
    };

    serialize_and_pack(&response)
}

/// Dispose plugin
///
/// Returns: packed (ptr, len) with result
#[no_mangle]
pub extern "C" fn plugin_dispose() -> u64 {
    unsafe {
        INITIALIZED = false;
    }

    let result = PluginResponse {
        handled: true,
        data: HashMap::from([
            ("status".to_string(), serde_json::json!("disposed")),
        ]),
    };

    serialize_and_pack(&result)
}

// ============================================================================
// Helpers
// ============================================================================

/// Serialize data to MessagePack and return packed pointer
fn serialize_and_pack<T: Serialize>(data: &T) -> u64 {
    let bytes = match rmp_serde::to_vec(data) {
        Ok(b) => b,
        Err(_) => return 0, // Return null pointer on error
    };

    let len = bytes.len() as u32;
    let ptr = alloc(len);

    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), ptr, len as usize);
    }

    pack_ptr_len(ptr as u32, len)
}

/// Pack pointer and length into u64
fn pack_ptr_len(ptr: u32, len: u32) -> u64 {
    ((ptr as u64) << 32) | (len as u64)
}

/// Pack error message
fn pack_error(msg: &str) -> u64 {
    let response = PluginResponse {
        handled: false,
        data: HashMap::from([
            ("error".to_string(), serde_json::json!(msg)),
        ]),
    };

    serialize_and_pack(&response)
}
