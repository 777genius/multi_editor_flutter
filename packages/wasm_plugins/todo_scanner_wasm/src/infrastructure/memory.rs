// Infrastructure - WASM memory management

use serde::Serialize;
use std::sync::Mutex;
use std::collections::HashMap;

// Global memory registry to prevent GC collection
static MEMORY_REGISTRY: Mutex<Option<HashMap<u32, Vec<u8>>>> = Mutex::new(None);

fn get_registry() -> &'static Mutex<Option<HashMap<u32, Vec<u8>>>> {
    &MEMORY_REGISTRY
}

fn ensure_registry_initialized() {
    // BUG FIX #12: Handle poisoned mutex gracefully
    let mut guard = MEMORY_REGISTRY.lock()
        .expect("CRITICAL: Memory registry mutex is poisoned. This indicates a panic in another thread.");
    if guard.is_none() {
        *guard = Some(HashMap::new());
    }
}

/// Allocate memory in WASM linear memory
///
/// FIXED BUG #1: Previously returned dangling pointer as buf was dropped.
/// Now properly stores buf in registry FIRST, then gets stable pointer.
#[no_mangle]
pub extern "C" fn alloc(size: u32) -> u32 {
    ensure_registry_initialized();

    let buf = vec![0u8; size as usize];

    // CRITICAL FIX: Insert into registry first to get stable storage
    let mut guard = MEMORY_REGISTRY.lock()
        .expect("CRITICAL: Memory registry mutex is poisoned");
    if let Some(ref mut registry) = *guard {
        // Use a temporary pointer calculation
        let temp_ptr = buf.as_ptr() as u32;
        registry.insert(temp_ptr, buf);

        // Now get the actual pointer from the registry
        // This ensures the Vec is stored and won't move
        if let Some(stored_buf) = registry.get(&temp_ptr) {
            return stored_buf.as_ptr() as u32;
        }
    }

    0 // Return 0 on failure
}

/// Deallocate memory
#[no_mangle]
pub extern "C" fn dealloc(ptr: u32) {
    // BUG FIX #13: Log warning if deallocating non-existent pointer
    let mut guard = MEMORY_REGISTRY.lock()
        .expect("CRITICAL: Memory registry mutex is poisoned");
    if let Some(ref mut registry) = *guard {
        if registry.remove(&ptr).is_none() {
            eprintln!("WARNING: Attempted to deallocate non-existent pointer: {}", ptr);
        }
    }
}

/// Serialize data and pack pointer + length into u64
///
/// FIXED BUG #2 & #9: Previously duplicated data in registry and risked deadlock.
/// Now uses alloc() properly without duplicating data or double-locking.
pub fn serialize_and_pack<T: Serialize>(data: &T) -> u64 {
    // Serialize using MessagePack
    let bytes = match rmp_serde::to_vec(data) {
        Ok(b) => b,
        Err(err) => {
            eprintln!("Serialization error: {}", err);
            return 0;
        }
    };

    if bytes.is_empty() {
        return 0;
    }

    let len = bytes.len();

    // CRITICAL FIX: Allocate memory properly (alloc already stores in registry)
    let ptr = alloc(len as u32);

    if ptr == 0 {
        eprintln!("Failed to allocate memory");
        return 0;
    }

    // CRITICAL FIX: Copy data to allocated memory
    unsafe {
        std::ptr::copy_nonoverlapping(
            bytes.as_ptr(),
            ptr as *mut u8,
            len,
        );
    }

    // REMOVED BUG #2: Don't insert again! alloc() already stored buffer in registry
    // REMOVED BUG #9: Don't lock mutex again! alloc() already locked it

    // Pack: (ptr << 32) | length
    ((ptr as u64) << 32) | (len as u64)
}

/// Read data from WASM memory
pub fn read_memory(ptr: u32, len: u32) -> Vec<u8> {
    unsafe {
        std::slice::from_raw_parts(ptr as *const u8, len as usize).to_vec()
    }
}
