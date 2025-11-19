// Domain Services - Business logic operations

use super::{TodoItem, TodoType, TodoPriority};

/// Service interface for scanning TODOs
pub trait TodoScanner {
    /// Scan source code and extract TODO items
    fn scan(&self, content: &str, language: &super::value_objects::Language) -> Vec<TodoItem>;
}

/// Extract author from TODO comment
/// Supports formats: TODO(john): ..., TODO(@john): ..., TODO[john]: ...
pub fn extract_author(text: &str) -> Option<String> {
    // Match patterns like (john), (@john), [john]
    let patterns = [
        regex::Regex::new(r"\((@?[\w\-]+)\)").ok()?,
        regex::Regex::new(r"\[(@?[\w\-]+)\]").ok()?,
    ];

    for pattern in &patterns {
        if let Some(captures) = pattern.captures(text) {
            if let Some(author) = captures.get(1) {
                return Some(author.as_str().to_string());
            }
        }
    }

    None
}

/// Extract tags from TODO comment
/// Supports format: #tag1 #tag2
pub fn extract_tags(text: &str) -> Vec<String> {
    let tag_pattern = regex::Regex::new(r"#([\w\-]+)").unwrap();
    tag_pattern
        .captures_iter(text)
        .filter_map(|cap| cap.get(1).map(|m| m.as_str().to_string()))
        .collect()
}

/// Extract priority from text content
/// Looks for !!! (high), !! (medium), ! (low)
pub fn extract_priority_from_text(text: &str) -> Option<TodoPriority> {
    if text.contains("!!!") {
        Some(TodoPriority::High)
    } else if text.contains("!!") {
        Some(TodoPriority::High)
    } else if text.contains("!") {
        Some(TodoPriority::Medium)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_author() {
        assert_eq!(extract_author("TODO(john): fix this"), Some("john".to_string()));
        assert_eq!(extract_author("TODO(@john): fix this"), Some("@john".to_string()));
        assert_eq!(extract_author("TODO[john]: fix this"), Some("john".to_string()));
        assert_eq!(extract_author("TODO: fix this"), None);
    }

    #[test]
    fn test_extract_tags() {
        let tags = extract_tags("TODO #bug #critical: fix this");
        assert_eq!(tags, vec!["bug", "critical"]);

        let tags = extract_tags("TODO: fix this");
        assert!(tags.is_empty());
    }

    #[test]
    fn test_extract_priority() {
        assert_eq!(extract_priority_from_text("!!! urgent"), Some(TodoPriority::High));
        assert_eq!(extract_priority_from_text("!! important"), Some(TodoPriority::High));
        assert_eq!(extract_priority_from_text("! note"), Some(TodoPriority::Medium));
        assert_eq!(extract_priority_from_text("normal"), None);
    }
}
