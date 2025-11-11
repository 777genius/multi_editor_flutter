/// Allocate memory in WASM linear memory
///
/// Host calls this to allocate space for input data.
/// Returns pointer to allocated memory.
///
/// ## Memory Ownership
/// - Allocator creates memory
/// - Caller must call `dealloc` to free
/// - Follow RAII pattern
#[no_mangle]
pub extern "C" fn alloc(size: u32) -> *mut u8 {
    // IMPORTANT: Create Vec with actual length, not just capacity
    // This ensures memory is properly allocated and initialized
    let mut buf = vec![0u8; size as usize];
    let ptr = buf.as_mut_ptr();
    std::mem::forget(buf); // Prevent Rust from deallocating
    ptr
}

/// Deallocate memory in WASM linear memory
///
/// Host calls this to free memory after reading result.
///
/// ## Safety
/// - Pointer must be from `alloc` call
/// - Size must match allocation size
/// - Pointer must not be used after deallocation
#[no_mangle]
pub extern "C" fn dealloc(ptr: *mut u8, size: u32) {
    unsafe {
        let _ = Vec::from_raw_parts(ptr, size as usize, size as usize);
        // Vec will be dropped and memory freed
    }
}

/// Pack pointer and length into u64
///
/// Used for returning (ptr, len) pairs from WASM functions.
/// Format: (ptr << 32) | len
pub fn pack_ptr_len(ptr: u32, len: u32) -> u64 {
    ((ptr as u64) << 32) | (len as u64)
}

/// Serialize data to MessagePack and return packed pointer
///
/// Helper for WASM exports.
pub fn serialize_and_pack<T: serde::Serialize>(data: &T) -> u64 {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_alloc_dealloc() {
        let size = 1024;
        let ptr = alloc(size);

        assert!(!ptr.is_null());

        // Write some data
        unsafe {
            *ptr = 42;
            assert_eq!(*ptr, 42);
        }

        // Free memory
        dealloc(ptr, size);
    }

    #[test]
    fn test_pack_ptr_len() {
        let ptr = 0x12345678u32;
        let len = 100u32;

        let packed = pack_ptr_len(ptr, len);

        // Unpack
        let unpacked_ptr = (packed >> 32) as u32;
        let unpacked_len = (packed & 0xFFFFFFFF) as u32;

        assert_eq!(unpacked_ptr, ptr);
        assert_eq!(unpacked_len, len);
    }
}
