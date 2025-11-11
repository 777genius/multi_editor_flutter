/// File Path (Value Object)
///
/// Represents a file path for searching.
/// Immutable and validated.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct FilePath {
    /// Full path
    path: String,

    /// File name only (cached for performance)
    file_name: String,
}

impl FilePath {
    /// Create new file path
    pub fn new(path: String) -> Result<Self, String> {
        if path.is_empty() {
            return Err("Path cannot be empty".to_string());
        }

        // Extract file name (support both Unix and Windows paths)
        let file_name = path
            .rsplit_once('/')
            .or_else(|| path.rsplit_once('\\'))
            .map(|(_, name)| name)
            .unwrap_or(&path)
            .to_string();

        Ok(Self { path, file_name })
    }

    /// Get full path
    pub fn path(&self) -> &str {
        &self.path
    }

    /// Get file name only
    pub fn file_name(&self) -> &str {
        &self.file_name
    }

    /// Get directory part (if any)
    pub fn directory(&self) -> Option<&str> {
        self.path.rsplit_once('/').or_else(|| self.path.rsplit_once('\\'))
            .map(|(dir, _)| dir)
    }

    /// Get file extension
    pub fn extension(&self) -> Option<&str> {
        self.file_name.rsplit_once('.').map(|(_, ext)| ext)
    }

    /// Check if path matches pattern (simple wildcard)
    pub fn matches_pattern(&self, pattern: &str) -> bool {
        // Simple implementation - can be enhanced
        if pattern.is_empty() || pattern == "*" {
            return true;
        }

        // Extension match (e.g., "*.rs")
        if let Some(ext_pattern) = pattern.strip_prefix("*.") {
            return self.extension() == Some(ext_pattern);
        }

        // Contains match
        self.path.contains(pattern)
    }
}

impl std::fmt::Display for FilePath {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.path)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_unix_path() {
        let path = FilePath::new("src/domain/mod.rs".to_string()).unwrap();
        assert_eq!(path.path(), "src/domain/mod.rs");
        assert_eq!(path.file_name(), "mod.rs");
        assert_eq!(path.directory(), Some("src/domain"));
        assert_eq!(path.extension(), Some("rs"));
    }

    #[test]
    fn test_windows_path() {
        let path = FilePath::new("src\\domain\\mod.rs".to_string()).unwrap();
        assert_eq!(path.file_name(), "mod.rs");
        assert_eq!(path.directory(), Some("src\\domain"));
    }

    #[test]
    fn test_file_only() {
        let path = FilePath::new("README.md".to_string()).unwrap();
        assert_eq!(path.file_name(), "README.md");
        assert_eq!(path.directory(), None);
        assert_eq!(path.extension(), Some("md"));
    }

    #[test]
    fn test_empty_path() {
        let path = FilePath::new("".to_string());
        assert!(path.is_err());
    }

    #[test]
    fn test_pattern_matching() {
        let path = FilePath::new("src/main.rs".to_string()).unwrap();
        assert!(path.matches_pattern("*"));
        assert!(path.matches_pattern("*.rs"));
        assert!(path.matches_pattern("src"));
        assert!(!path.matches_pattern("*.js"));
    }
}
