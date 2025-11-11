/// Match Score (Value Object)
///
/// Represents the quality of a fuzzy match (0-100).
/// Higher score = better match.
/// Immutable and comparable.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct MatchScore {
    value: u16, // Internal: 0-10000 for precision, exposed as 0-100
}

impl MatchScore {
    /// Create new match score (0-100)
    pub fn new(score: u16) -> Result<Self, String> {
        if score > 100 {
            return Err(format!("Score must be 0-100, got: {}", score));
        }
        Ok(Self { value: score * 100 }) // Store as 0-10000 internally
    }

    /// Create from raw internal value (used by infrastructure)
    pub(crate) fn from_raw(raw: u16) -> Self {
        Self {
            value: raw.min(10_000),
        }
    }

    /// Get score as 0-100
    pub fn as_u8(&self) -> u8 {
        (self.value / 100).min(100) as u8
    }

    /// Get score as 0.0-1.0
    pub fn as_float(&self) -> f32 {
        (self.value as f32) / 10_000.0
    }

    /// Get raw internal value (0-10000)
    pub(crate) fn raw(&self) -> u16 {
        self.value
    }

    /// Check if score meets threshold
    pub fn meets_threshold(&self, threshold: u8) -> bool {
        self.as_u8() >= threshold
    }

    /// Perfect match score
    pub fn perfect() -> Self {
        Self { value: 10_000 }
    }

    /// Zero score (no match)
    pub fn zero() -> Self {
        Self { value: 0 }
    }
}

impl Default for MatchScore {
    fn default() -> Self {
        Self::zero()
    }
}

impl std::fmt::Display for MatchScore {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.as_u8())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_score() {
        let score = MatchScore::new(75).unwrap();
        assert_eq!(score.as_u8(), 75);
    }

    #[test]
    fn test_invalid_score() {
        let score = MatchScore::new(150);
        assert!(score.is_err());
    }

    #[test]
    fn test_score_comparison() {
        let score1 = MatchScore::new(80).unwrap();
        let score2 = MatchScore::new(60).unwrap();
        assert!(score1 > score2);
    }

    #[test]
    fn test_threshold() {
        let score = MatchScore::new(75).unwrap();
        assert!(score.meets_threshold(70));
        assert!(!score.meets_threshold(80));
    }

    #[test]
    fn test_perfect_zero() {
        assert_eq!(MatchScore::perfect().as_u8(), 100);
        assert_eq!(MatchScore::zero().as_u8(), 0);
    }

    #[test]
    fn test_as_float() {
        let score = MatchScore::new(50).unwrap();
        assert!((score.as_float() - 0.5).abs() < 0.01);
    }
}
