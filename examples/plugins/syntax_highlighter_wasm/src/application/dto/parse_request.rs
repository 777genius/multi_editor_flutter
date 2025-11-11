use serde::{Deserialize, Serialize};

/// Parse Request DTO
///
/// Input for parse use case.
/// Simple, serializable, validated.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParseRequest {
    /// Language identifier (rust, dart, javascript, etc.)
    pub language: String,

    /// Source code to parse
    pub source_code: String,

    /// Optional: enable incremental parsing
    #[serde(default)]
    pub incremental: bool,
}

impl ParseRequest {
    /// Validate request
    pub fn validate(&self) -> Result<(), String> {
        if self.source_code.is_empty() {
            return Err("Source code cannot be empty".to_string());
        }

        if self.language.is_empty() {
            return Err("Language must be specified".to_string());
        }

        // Check reasonable size limit (prevent DoS)
        const MAX_SIZE: usize = 10 * 1024 * 1024; // 10MB
        if self.source_code.len() > MAX_SIZE {
            return Err(format!(
                "Source code too large: {} bytes (max: {} bytes)",
                self.source_code.len(),
                MAX_SIZE
            ));
        }

        Ok(())
    }
}
