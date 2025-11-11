use crate::domain::value_objects::{FilePath, MatchScore};

/// Fuzzy Match (Entity)
///
/// Represents a single search result with match quality.
/// Has identity (match_id) and contains rich information about the match.
#[derive(Debug, Clone)]
pub struct FuzzyMatch {
    /// Unique match identifier
    match_id: String,

    /// Matched file path
    file_path: FilePath,

    /// Match quality score
    score: MatchScore,

    /// Character indices that matched (for highlighting)
    match_indices: Vec<usize>,

    /// Ranking position (set after sorting)
    rank: Option<usize>,
}

impl FuzzyMatch {
    /// Create new fuzzy match
    pub fn new(
        match_id: String,
        file_path: FilePath,
        score: MatchScore,
        match_indices: Vec<usize>,
    ) -> Self {
        Self {
            match_id,
            file_path,
            score,
            match_indices,
            rank: None,
        }
    }

    /// Set rank position
    pub fn with_rank(mut self, rank: usize) -> Self {
        self.rank = Some(rank);
        self
    }

    // Getters
    pub fn match_id(&self) -> &str {
        &self.match_id
    }

    pub fn file_path(&self) -> &FilePath {
        &self.file_path
    }

    pub fn score(&self) -> MatchScore {
        self.score
    }

    pub fn match_indices(&self) -> &[usize] {
        &self.match_indices
    }

    pub fn rank(&self) -> Option<usize> {
        self.rank
    }

    /// Get highlighted path with markers
    pub fn highlighted_path(&self) -> String {
        let path = self.file_path.path();
        let mut result = String::new();
        let chars: Vec<char> = path.chars().collect();

        for (i, ch) in chars.iter().enumerate() {
            if self.match_indices.contains(&i) {
                result.push_str(&format!("[{}]", ch));
            } else {
                result.push(*ch);
            }
        }

        result
    }

    /// Check if this is a better match than another
    pub fn is_better_than(&self, other: &FuzzyMatch) -> bool {
        // Primary: higher score
        if self.score != other.score {
            return self.score > other.score;
        }

        // Secondary: shorter path (more specific)
        if self.file_path.path().len() != other.file_path.path().len() {
            return self.file_path.path().len() < other.file_path.path().len();
        }

        // Tertiary: alphabetical
        self.file_path.path() < other.file_path.path()
    }
}

impl PartialEq for FuzzyMatch {
    fn eq(&self, other: &Self) -> bool {
        self.match_id == other.match_id
    }
}

impl Eq for FuzzyMatch {}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_match(id: &str, path: &str, score: u16, indices: Vec<usize>) -> FuzzyMatch {
        FuzzyMatch::new(
            id.to_string(),
            FilePath::new(path.to_string()).unwrap(),
            MatchScore::new(score).unwrap(),
            indices,
        )
    }

    #[test]
    fn test_match_creation() {
        let m = create_match("m1", "src/main.rs", 85, vec![0, 4, 5]);
        assert_eq!(m.match_id(), "m1");
        assert_eq!(m.file_path().path(), "src/main.rs");
        assert_eq!(m.score().as_u8(), 85);
        assert_eq!(m.match_indices(), &[0, 4, 5]);
        assert_eq!(m.rank(), None);
    }

    #[test]
    fn test_with_rank() {
        let m = create_match("m1", "src/main.rs", 85, vec![]).with_rank(5);
        assert_eq!(m.rank(), Some(5));
    }

    #[test]
    fn test_is_better_than() {
        let m1 = create_match("m1", "src/main.rs", 90, vec![]);
        let m2 = create_match("m2", "test/main.rs", 80, vec![]);
        assert!(m1.is_better_than(&m2));

        // Same score - shorter path wins
        let m3 = create_match("m3", "main.rs", 90, vec![]);
        let m4 = create_match("m4", "src/main.rs", 90, vec![]);
        assert!(m3.is_better_than(&m4));
    }

    #[test]
    fn test_highlighted_path() {
        let m = create_match("m1", "main", 85, vec![0, 2]);
        let highlighted = m.highlighted_path();
        assert_eq!(highlighted, "[m]a[i]n");
    }
}
