use crate::domain::value_objects::{Range, HighlightStyle};
use serde::{Deserialize, Serialize};

/// Highlight Range Entity
///
/// Represents a highlighted region in source code with associated style.
/// Has identity (unique ID for tracking), mutable (can update style/range).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HighlightRange {
    /// Unique identifier
    id: String,

    /// Text range to highlight
    range: Range,

    /// Token type (keyword, string, comment, etc.)
    token_type: String,

    /// Optional: actual text content (for validation)
    #[serde(skip_serializing_if = "Option::is_none")]
    text: Option<String>,
}

impl HighlightRange {
    /// Create new highlight range
    pub fn new(id: String, range: Range, token_type: String) -> Self {
        Self {
            id,
            range,
            token_type,
            text: None,
        }
    }

    /// Create with text content
    pub fn with_text(mut self, text: String) -> Self {
        self.text = Some(text);
        self
    }

    /// Get range ID (entity identity)
    pub fn id(&self) -> &str {
        &self.id
    }

    /// Get text range
    pub fn range(&self) -> Range {
        self.range
    }

    /// Get token type
    pub fn token_type(&self) -> &str {
        &self.token_type
    }

    /// Get text content (if available)
    pub fn text(&self) -> Option<&str> {
        self.text.as_deref()
    }

    /// Check if this range overlaps with another
    pub fn overlaps_with(&self, other: &HighlightRange) -> bool {
        self.range.overlaps(&other.range)
    }

    /// Get byte length of highlighted region
    pub fn byte_length(&self) -> Option<usize> {
        self.text.as_ref().map(|t| t.len())
    }
}

/// Highlight Collection
///
/// Aggregate of HighlightRange entities.
/// Provides operations on collections of highlights (sorting, merging, etc.).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HighlightCollection {
    ranges: Vec<HighlightRange>,
}

impl HighlightCollection {
    /// Create empty collection
    pub fn new() -> Self {
        Self {
            ranges: Vec::new(),
        }
    }

    /// Create from vector
    pub fn from_vec(ranges: Vec<HighlightRange>) -> Self {
        Self { ranges }
    }

    /// Add highlight range
    pub fn add(&mut self, range: HighlightRange) {
        self.ranges.push(range);
    }

    /// Get all ranges
    pub fn ranges(&self) -> &[HighlightRange] {
        &self.ranges
    }

    /// Sort ranges by position (for efficient rendering)
    pub fn sort_by_position(&mut self) {
        self.ranges.sort_by(|a, b| {
            a.range().start.cmp(&b.range().start)
        });
    }

    /// Filter by token type
    pub fn filter_by_type(&self, token_type: &str) -> Vec<&HighlightRange> {
        self.ranges
            .iter()
            .filter(|r| r.token_type() == token_type)
            .collect()
    }

    /// Get total highlighted bytes
    pub fn total_highlighted_bytes(&self) -> usize {
        self.ranges
            .iter()
            .filter_map(|r| r.byte_length())
            .sum()
    }

    /// Check for overlapping ranges (quality check)
    pub fn has_overlaps(&self) -> bool {
        for i in 0..self.ranges.len() {
            for j in (i + 1)..self.ranges.len() {
                if self.ranges[i].overlaps_with(&self.ranges[j]) {
                    return true;
                }
            }
        }
        false
    }
}

impl Default for HighlightCollection {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::value_objects::Position;

    #[test]
    fn test_highlight_range_creation() {
        let range = Range::new(
            Position::new(0, 0),
            Position::new(0, 5),
        ).unwrap();

        let highlight = HighlightRange::new(
            "h1".to_string(),
            range,
            "keyword".to_string(),
        );

        assert_eq!(highlight.token_type(), "keyword");
        assert!(highlight.text().is_none());
    }

    #[test]
    fn test_highlight_collection() {
        let mut collection = HighlightCollection::new();

        let r1 = Range::new(Position::new(0, 0), Position::new(0, 2)).unwrap();
        let r2 = Range::new(Position::new(0, 5), Position::new(0, 8)).unwrap();

        collection.add(HighlightRange::new("h1".to_string(), r2, "keyword".to_string()));
        collection.add(HighlightRange::new("h2".to_string(), r1, "string".to_string()));

        collection.sort_by_position();

        // After sorting, r1 should be first (starts at position 0)
        assert_eq!(collection.ranges()[0].id(), "h2");
        assert!(!collection.has_overlaps());
    }
}
