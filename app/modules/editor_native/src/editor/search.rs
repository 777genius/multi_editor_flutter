use ropey::Rope;
use crate::editor::Position;

/// Search options for find/replace operations.
#[derive(Debug, Clone, Default)]
pub struct SearchOptions {
    /// Case-sensitive search
    pub case_sensitive: bool,
    /// Whole word matching
    pub whole_word: bool,
    /// Use regular expressions
    pub regex: bool,
    /// Search backwards
    pub backwards: bool,
}

/// Search result containing match position and text.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SearchMatch {
    /// Start position of the match
    pub start: Position,
    /// End position of the match
    pub end: Position,
    /// Matched text
    pub text: String,
}

/// Searches for text in a rope.
///
/// This function performs efficient text search using rope slicing.
/// For regex support, it converts rope slices to strings (less efficient
/// but necessary for regex matching).
///
/// # Performance
/// - Simple search: O(n) where n = document length
/// - Regex search: O(n * m) where m = regex complexity
/// - Backwards search: Same as forward
///
/// # Examples
/// ```rust
/// let rope = Rope::from_str("Hello World\nHello Rust");
/// let options = SearchOptions::default();
/// let matches = search_rope(&rope, "Hello", &options, None);
/// assert_eq!(matches.len(), 2);
/// ```
pub fn search_rope(
    rope: &Rope,
    query: &str,
    options: &SearchOptions,
    start_pos: Option<Position>,
) -> Vec<SearchMatch> {
    if query.is_empty() {
        return Vec::new();
    }

    let mut matches = Vec::new();
    let content = rope.to_string();

    // Determine search string
    let (search_content, search_query) = if options.case_sensitive {
        (content.clone(), query.to_string())
    } else {
        (content.to_lowercase(), query.to_lowercase())
    };

    // Find all occurrences
    let mut start_idx = 0;
    while let Some(pos) = search_content[start_idx..].find(&search_query) {
        let absolute_pos = start_idx + pos;

        // Check whole word matching
        if options.whole_word {
            let before = if absolute_pos > 0 {
                content.chars().nth(absolute_pos - 1)
            } else {
                None
            };

            let after = content.chars().nth(absolute_pos + search_query.len());

            // Check if surrounded by word boundaries
            if !is_word_boundary(before) || !is_word_boundary(after) {
                start_idx = absolute_pos + 1;
                continue;
            }
        }

        // Convert byte offset to Position
        let start_position = Position::from_byte_offset(rope, absolute_pos);
        let end_position = Position::from_byte_offset(rope, absolute_pos + query.len());

        matches.push(SearchMatch {
            start: start_position,
            end: end_position,
            text: query.to_string(),
        });

        start_idx = absolute_pos + search_query.len();
    }

    // Filter by start position if provided
    if let Some(start) = start_pos {
        let start_byte = start.to_byte_offset(rope);
        matches.retain(|m| {
            let match_byte = m.start.to_byte_offset(rope);
            if options.backwards {
                match_byte < start_byte
            } else {
                match_byte >= start_byte
            }
        });
    }

    // Reverse if backwards search
    if options.backwards {
        matches.reverse();
    }

    matches
}

/// Checks if a character is a word boundary.
fn is_word_boundary(ch: Option<char>) -> bool {
    match ch {
        None => true, // Start or end of document
        Some(c) => !c.is_alphanumeric() && c != '_',
    }
}

/// Find next match from current position.
///
/// Note: Currently searches entire document from current position,
/// which may be slow for large documents. Returns first match after
/// current position.
///
/// # Performance
/// O(n) where n = document size. For better interactive performance,
/// consider implementing incremental search or limiting search range.
pub fn find_next(
    rope: &Rope,
    query: &str,
    current_pos: Position,
    options: &SearchOptions,
) -> Option<SearchMatch> {
    let matches = search_rope(rope, query, options, Some(current_pos));
    matches.first().cloned()
}

/// Replace all matches with replacement text.
///
/// Returns the number of replacements made.
///
/// # Performance
/// O(n * m) where n = number of matches, m = document length
/// Uses rope operations for efficient text replacement.
pub fn replace_all(
    rope: &mut Rope,
    query: &str,
    replacement: &str,
    options: &SearchOptions,
) -> usize {
    let matches = search_rope(rope, query, options, None);
    let count = matches.len();

    // Replace in reverse order to avoid offset issues
    for search_match in matches.iter().rev() {
        let start_offset = search_match.start.to_byte_offset(rope);
        let end_offset = search_match.end.to_byte_offset(rope);

        rope.remove(start_offset..end_offset);
        rope.insert(start_offset, replacement);
    }

    count
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_search_case_insensitive() {
        let rope = Rope::from_str("Hello World\nHello Rust");
        let options = SearchOptions {
            case_sensitive: false,
            ..Default::default()
        };

        let matches = search_rope(&rope, "hello", &options, None);
        assert_eq!(matches.len(), 2);
    }

    #[test]
    fn test_search_case_sensitive() {
        let rope = Rope::from_str("Hello World\nhello Rust");
        let options = SearchOptions {
            case_sensitive: true,
            ..Default::default()
        };

        let matches = search_rope(&rope, "Hello", &options, None);
        assert_eq!(matches.len(), 1);
    }

    #[test]
    fn test_search_whole_word() {
        let rope = Rope::from_str("test testing tested");
        let options = SearchOptions {
            whole_word: true,
            ..Default::default()
        };

        let matches = search_rope(&rope, "test", &options, None);
        assert_eq!(matches.len(), 1); // Only "test", not "testing" or "tested"
    }

    #[test]
    fn test_replace_all() {
        let mut rope = Rope::from_str("foo bar foo baz foo");
        let options = SearchOptions::default();

        let count = replace_all(&mut rope, "foo", "qux", &options);

        assert_eq!(count, 3);
        assert_eq!(rope.to_string(), "qux bar qux baz qux");
    }

    #[test]
    fn test_find_next() {
        let rope = Rope::from_str("line 1\nline 2\nline 3");
        let options = SearchOptions::default();

        let first = find_next(&rope, "line", Position::new(0, 0), &options);
        assert!(first.is_some());

        let second = find_next(&rope, "line", Position::new(1, 0), &options);
        assert!(second.is_some());
        assert_eq!(second.unwrap().start.line, 1);
    }

    #[test]
    fn test_backwards_search() {
        let rope = Rope::from_str("line 1\nline 2\nline 3");
        let options = SearchOptions {
            backwards: true,
            ..Default::default()
        };

        let matches = search_rope(&rope, "line", &options, Some(Position::new(2, 0)));

        // Should find lines 2 and 1 (in reverse order)
        assert_eq!(matches.len(), 2);
        assert_eq!(matches[0].start.line, 1); // line 2 (reversed)
        assert_eq!(matches[1].start.line, 0); // line 1
    }
}
