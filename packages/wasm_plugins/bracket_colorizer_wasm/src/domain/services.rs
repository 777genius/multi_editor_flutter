// Domain Services - Business logic operations

use super::{
    Bracket, BracketPair, BracketCollection, UnmatchedBracket, UnmatchedReason,
    BracketType, BracketSide, Position, ColorLevel, ColorScheme, Language,
};

/// Service interface for bracket analysis
pub trait BracketAnalyzer {
    /// Analyze source code and extract bracket pairs
    fn analyze(&self, content: &str, language: Language) -> BracketCollection;
}

/// Stack-based bracket matcher
///
/// This is the core algorithm for matching brackets:
/// 1. Scan through source code
/// 2. Push opening brackets onto stack
/// 3. Pop matching closing brackets
/// 4. Track depth and assign colors
pub struct StackBasedMatcher {
    color_scheme: ColorScheme,
}

impl StackBasedMatcher {
    pub fn new(color_scheme: ColorScheme) -> Self {
        Self { color_scheme }
    }

    /// Match brackets using stack algorithm
    pub fn match_brackets(&self, content: &str, language: Language) -> BracketCollection {
        let start_time = std::time::Instant::now();

        let mut pairs = Vec::new();
        let mut unmatched = Vec::new();
        let mut stack: Vec<Bracket> = Vec::new();
        let mut max_depth = 0;

        // Track if we're inside a string or comment
        let mut in_string = false;
        let mut in_single_quote_string = false;
        let mut in_comment = false;
        let mut in_multiline_comment = false;
        let mut escape_next = false;

        let chars: Vec<char> = content.chars().collect();
        let mut offset = 0u32;
        let mut line = 0u32;
        let mut column = 0u32;

        let mut i = 0;
        while i < chars.len() {
            let ch = chars[i];

            // Handle escape sequences
            // FIXED BUG #8: When escaping a newline, still update line counter
            if escape_next {
                escape_next = false;
                if ch == '\n' {
                    line += 1;
                    column = 0;
                } else {
                    column += 1;
                }
                offset += 1;
                i += 1;
                continue;
            }

            if ch == '\\' && (in_string || in_single_quote_string) {
                escape_next = true;
                offset += 1;
                column += 1;
                i += 1;
                continue;
            }

            // Handle newlines
            if ch == '\n' {
                line += 1;
                column = 0;
                offset += 1;
                in_comment = false; // Single-line comments end
                i += 1;
                continue;
            }

            // Handle strings
            if ch == '"' && !in_single_quote_string && !in_comment && !in_multiline_comment {
                in_string = !in_string;
            } else if ch == '\'' && !in_string && !in_comment && !in_multiline_comment {
                in_single_quote_string = !in_single_quote_string;
            }

            // Handle comments (simplified, works for C-style comments)
            if !in_string && !in_single_quote_string {
                // Check for // single-line comment
                if i + 1 < chars.len() && ch == '/' && chars[i + 1] == '/' {
                    in_comment = true;
                }

                // Check for /* multi-line comment start
                if i + 1 < chars.len() && ch == '/' && chars[i + 1] == '*' {
                    in_multiline_comment = true;
                }

                // Check for */ multi-line comment end
                // FIXED BUG #4: Don't increment i by 2, the loop will add 1
                if i + 1 < chars.len() && ch == '*' && chars[i + 1] == '/' {
                    in_multiline_comment = false;
                    offset += 2;
                    column += 2;
                    i += 1; // CRITICAL FIX: Only increment by 1, loop adds another 1
                    continue;
                }
            }

            // Only process brackets if not in string or comment
            if !in_string && !in_single_quote_string && !in_comment && !in_multiline_comment {
                if let Some((bracket_type, side)) = BracketType::from_char(ch) {
                    // Skip angle brackets in generic-supporting languages
                    // This is a simplified check; real implementation would use AST
                    if bracket_type == BracketType::Angle
                        && language.uses_angle_brackets_as_generics()
                    {
                        // Check if this looks like a generic (simplified heuristic)
                        let is_likely_generic = self.is_likely_generic_bracket(&chars, i);
                        if is_likely_generic {
                            offset += 1;
                            column += 1;
                            i += 1;
                            continue;
                        }
                    }

                    let position = Position::new(line, column, offset);
                    let depth = stack.len();
                    let color_level = ColorLevel::from_depth(depth, self.color_scheme.color_count());

                    let bracket = Bracket::new(bracket_type, side, position, depth, color_level);

                    match side {
                        BracketSide::Opening => {
                            // Push opening bracket onto stack
                            stack.push(bracket);
                            if depth > max_depth {
                                max_depth = depth;
                            }
                        }
                        BracketSide::Closing => {
                            // Try to match with opening bracket
                            if let Some(opening) = stack.pop() {
                                if opening.bracket_type == bracket_type {
                                    // Matched pair!
                                    pairs.push(BracketPair::new(opening, bracket));
                                } else {
                                    // Type mismatch - save bracket_type before moving
                                    let opening_type = opening.bracket_type;
                                    unmatched.push(UnmatchedBracket {
                                        bracket: bracket.clone(),
                                        reason: UnmatchedReason::TypeMismatch {
                                            expected: opening_type,
                                            found: bracket_type,
                                        },
                                    });
                                    unmatched.push(UnmatchedBracket {
                                        bracket: opening,
                                        reason: UnmatchedReason::TypeMismatch {
                                            expected: bracket_type,
                                            found: opening_type,
                                        },
                                    });
                                }
                            } else {
                                // No matching opening bracket
                                unmatched.push(UnmatchedBracket {
                                    bracket,
                                    reason: UnmatchedReason::MissingOpening,
                                });
                            }
                        }
                    }
                }
            }

            offset += 1;
            column += 1;
            i += 1;
        }

        // Any remaining opening brackets are unmatched
        for opening in stack {
            unmatched.push(UnmatchedBracket {
                bracket: opening,
                reason: UnmatchedReason::MissingClosing,
            });
        }

        let duration = start_time.elapsed();

        BracketCollection::new(pairs, unmatched, max_depth, duration.as_millis() as u64)
    }

    /// Heuristic to detect if angle bracket is likely a generic/template
    /// This is simplified; real implementation would use AST
    fn is_likely_generic_bracket(&self, chars: &[char], pos: usize) -> bool {
        // Look for patterns like: Vec<T>, HashMap<K, V>, std::vector<int>
        // Check if there's an identifier before <
        if pos > 0 {
            let prev_char = chars[pos - 1];
            if prev_char.is_alphanumeric() || prev_char == '_' {
                return true;
            }
        }

        // Check if there's an identifier after >
        if pos + 1 < chars.len() {
            let next_char = chars[pos + 1];
            if next_char.is_alphanumeric() || next_char == '_' || next_char == ',' || next_char == ' ' {
                return true;
            }
        }

        false
    }
}

impl BracketAnalyzer for StackBasedMatcher {
    fn analyze(&self, content: &str, language: Language) -> BracketCollection {
        self.match_brackets(content, language)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simple_bracket_matching() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "function test() { return 42; }";

        let result = matcher.analyze(content, Language::JavaScript);

        assert_eq!(result.pairs.len(), 2); // () and {}
        assert_eq!(result.unmatched.len(), 0);
        assert!(!result.has_errors());
    }

    #[test]
    fn test_nested_brackets() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "{ [ ( ) ] }";

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.pairs.len(), 3); // (), [], {}
        assert_eq!(result.max_depth, 2); // Max nesting level
    }

    #[test]
    fn test_unmatched_opening() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "{ ( }"; // Type mismatch: } doesn't match (, plus { is unmatched

        let result = matcher.analyze(content, Language::Generic);

        // Correct expectation: ( and } are mismatched (2), and { is left unmatched (1) = 3 total
        assert_eq!(result.unmatched.len(), 3);
        assert!(result.has_errors());
    }

    #[test]
    fn test_unmatched_closing() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "{ } )"; // Extra )

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.unmatched.len(), 1);
    }

    #[test]
    fn test_type_mismatch() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "( ]"; // Mismatched

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.unmatched.len(), 2);
        assert!(result.has_errors());
    }

    #[test]
    fn test_brackets_in_strings() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = r#"{ let s = "{ not a bracket }"; }"#;

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.pairs.len(), 1); // Only outer {}
    }

    #[test]
    fn test_brackets_in_comments() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "{ // ( not counted\n }";

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.pairs.len(), 1); // Only outer {}
    }

    #[test]
    fn test_color_level_assignment() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "{ [ ( ) ] }";

        let result = matcher.analyze(content, Language::Generic);

        // Check that colors are assigned based on depth
        let outer_pair = &result.pairs[2]; // {}
        let middle_pair = &result.pairs[1]; // []
        let inner_pair = &result.pairs[0]; // ()

        assert_eq!(outer_pair.depth, 0);
        assert_eq!(middle_pair.depth, 1);
        assert_eq!(inner_pair.depth, 2);
    }

    #[test]
    fn test_statistics() {
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "{ ( ) [ ] }";

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.statistics.round_pairs, 1);
        assert_eq!(result.statistics.square_pairs, 1);
        assert_eq!(result.statistics.curly_pairs, 1);
        assert_eq!(result.statistics.total_pairs(), 3);
    }

    // NEW TESTS FOR EDGE CASES (Bug fixes #14-16)

    #[test]
    fn test_empty_content() {
        // BUG FIX #14: Test empty content
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "";

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.pairs.len(), 0);
        assert_eq!(result.unmatched.len(), 0);
        assert_eq!(result.max_depth, 0);
    }

    #[test]
    fn test_very_deep_nesting() {
        // BUG FIX #15: Test very deep nesting (100 levels)
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let depth = 100;
        let mut content = String::new();

        // Create 100 levels of nesting
        for _ in 0..depth {
            content.push('{');
        }
        for _ in 0..depth {
            content.push('}');
        }

        let result = matcher.analyze(&content, Language::Generic);

        assert_eq!(result.pairs.len(), depth);
        assert_eq!(result.unmatched.len(), 0);
        assert_eq!(result.max_depth, depth - 1); // Max depth is 99 (0-indexed)
    }

    #[test]
    fn test_escaped_quotes_in_strings() {
        // BUG FIX #16: Test escaped quotes don't break string detection
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = r#"let str = "He said \"hello {world}\" here"; let obj = {a: 1};"#;

        let result = matcher.analyze(content, Language::Generic);

        // Should only find the {a: 1} bracket, not the one in the string
        assert_eq!(result.pairs.len(), 1);
        assert_eq!(result.unmatched.len(), 0);

        // Verify it's the curly bracket
        assert_eq!(result.statistics.curly_pairs, 1);
        assert_eq!(result.statistics.round_pairs, 0);
    }

    #[test]
    fn test_multiline_strings_with_escaped_newlines() {
        // Additional edge case: escaped newlines in strings
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "let s = \"line1\\\nline2 {not_bracket}\"; {real}";

        let result = matcher.analyze(content, Language::Generic);

        // Should only find {real}, not the one in the string
        assert_eq!(result.pairs.len(), 1);
        assert_eq!(result.statistics.curly_pairs, 1);
    }

    #[test]
    fn test_only_whitespace() {
        // Edge case: only whitespace
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "   \n\t\r\n   ";

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.pairs.len(), 0);
        assert_eq!(result.unmatched.len(), 0);
    }

    #[test]
    fn test_unicode_brackets() {
        // Edge case: Unicode text around brackets
        let matcher = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let content = "let 日本語 = {value: '値'};";

        let result = matcher.analyze(content, Language::Generic);

        assert_eq!(result.pairs.len(), 1);
        assert_eq!(result.statistics.curly_pairs, 1);
    }
}
