use crate::domain::entities::FuzzyMatch;
use crate::domain::value_objects::MatchScore;

/// Match Collection (Aggregate Root)
///
/// Collection of fuzzy matches with operations.
/// Maintains consistency and business rules.
#[derive(Debug, Clone)]
pub struct MatchCollection {
    matches: Vec<FuzzyMatch>,
    is_sorted: bool,
}

impl MatchCollection {
    /// Create new empty collection
    pub fn new() -> Self {
        Self {
            matches: Vec::new(),
            is_sorted: false,
        }
    }

    /// Create from vector of matches
    pub fn from_matches(matches: Vec<FuzzyMatch>) -> Self {
        Self {
            matches,
            is_sorted: false,
        }
    }

    /// Add match to collection
    pub fn add(&mut self, fuzzy_match: FuzzyMatch) {
        self.matches.push(fuzzy_match);
        self.is_sorted = false;
    }

    /// Sort matches by score (descending)
    pub fn sort_by_score(&mut self) {
        self.matches.sort_by(|a, b| {
            // Use is_better_than which implements full comparison logic
            if a.is_better_than(b) {
                std::cmp::Ordering::Less
            } else if b.is_better_than(a) {
                std::cmp::Ordering::Greater
            } else {
                std::cmp::Ordering::Equal
            }
        });

        // Assign ranks
        for (i, m) in self.matches.iter_mut().enumerate() {
            *m = m.clone().with_rank(i + 1);
        }

        self.is_sorted = true;
    }

    /// Filter matches by minimum score
    pub fn filter_by_score(mut self, min_score: u8) -> Self {
        self.matches.retain(|m| m.score().meets_threshold(min_score));
        self
    }

    /// Take top N matches
    pub fn take(mut self, n: usize) -> Self {
        if !self.is_sorted {
            self.sort_by_score();
        }
        self.matches.truncate(n);
        self
    }

    /// Get all matches
    pub fn matches(&self) -> &[FuzzyMatch] {
        &self.matches
    }

    /// Get match count
    pub fn len(&self) -> usize {
        self.matches.len()
    }

    /// Check if empty
    pub fn is_empty(&self) -> bool {
        self.matches.is_empty()
    }

    /// Get top match (if any)
    pub fn top_match(&self) -> Option<&FuzzyMatch> {
        if !self.is_sorted {
            return None;
        }
        self.matches.first()
    }

    /// Get statistics
    pub fn statistics(&self) -> CollectionStatistics {
        if self.is_empty() {
            return CollectionStatistics::default();
        }

        let scores: Vec<u8> = self.matches.iter().map(|m| m.score().as_u8()).collect();
        let avg_score = scores.iter().map(|&s| s as f32).sum::<f32>() / scores.len() as f32;
        let max_score = *scores.iter().max().unwrap_or(&0);
        let min_score = *scores.iter().min().unwrap_or(&0);

        CollectionStatistics {
            total_matches: self.len(),
            average_score: avg_score,
            max_score,
            min_score,
        }
    }
}

/// Collection Statistics (Value Object)
#[derive(Debug, Clone, Default)]
pub struct CollectionStatistics {
    pub total_matches: usize,
    pub average_score: f32,
    pub max_score: u8,
    pub min_score: u8,
}

impl Default for MatchCollection {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::value_objects::FilePath;

    fn create_match(id: &str, path: &str, score: u16) -> FuzzyMatch {
        FuzzyMatch::new(
            id.to_string(),
            FilePath::new(path.to_string()).unwrap(),
            MatchScore::new(score).unwrap(),
            vec![],
        )
    }

    #[test]
    fn test_collection_creation() {
        let collection = MatchCollection::new();
        assert_eq!(collection.len(), 0);
        assert!(collection.is_empty());
    }

    #[test]
    fn test_add_match() {
        let mut collection = MatchCollection::new();
        collection.add(create_match("m1", "test.rs", 80));
        assert_eq!(collection.len(), 1);
    }

    #[test]
    fn test_sort_by_score() {
        let mut collection = MatchCollection::new();
        collection.add(create_match("m1", "test1.rs", 60));
        collection.add(create_match("m2", "test2.rs", 90));
        collection.add(create_match("m3", "test3.rs", 75));

        collection.sort_by_score();

        let matches = collection.matches();
        assert_eq!(matches[0].score().as_u8(), 90);
        assert_eq!(matches[1].score().as_u8(), 75);
        assert_eq!(matches[2].score().as_u8(), 60);

        // Check ranks
        assert_eq!(matches[0].rank(), Some(1));
        assert_eq!(matches[1].rank(), Some(2));
        assert_eq!(matches[2].rank(), Some(3));
    }

    #[test]
    fn test_filter_by_score() {
        let mut collection = MatchCollection::new();
        collection.add(create_match("m1", "test1.rs", 60));
        collection.add(create_match("m2", "test2.rs", 90));
        collection.add(create_match("m3", "test3.rs", 75));

        let filtered = collection.filter_by_score(70);
        assert_eq!(filtered.len(), 2); // 90 and 75
    }

    #[test]
    fn test_take() {
        let mut collection = MatchCollection::new();
        collection.add(create_match("m1", "test1.rs", 60));
        collection.add(create_match("m2", "test2.rs", 90));
        collection.add(create_match("m3", "test3.rs", 75));

        let top2 = collection.take(2);
        assert_eq!(top2.len(), 2);
        assert_eq!(top2.matches()[0].score().as_u8(), 90);
    }

    #[test]
    fn test_statistics() {
        let mut collection = MatchCollection::new();
        collection.add(create_match("m1", "test1.rs", 60));
        collection.add(create_match("m2", "test2.rs", 80));
        collection.add(create_match("m3", "test3.rs", 100));

        let stats = collection.statistics();
        assert_eq!(stats.total_matches, 3);
        assert_eq!(stats.max_score, 100);
        assert_eq!(stats.min_score, 60);
        assert!((stats.average_score - 80.0).abs() < 0.1);
    }
}
