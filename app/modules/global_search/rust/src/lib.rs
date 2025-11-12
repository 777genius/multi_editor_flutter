use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use regex::Regex;
use std::collections::HashSet;

/// A single match found in a file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchMatch {
    /// File path where match was found
    pub file_path: String,
    /// Line number (1-indexed)
    pub line_number: usize,
    /// Column number where match starts (0-indexed)
    pub column: usize,
    /// The matched line content
    pub line_content: String,
    /// Length of the matched text
    pub match_length: usize,
    /// Lines before the match (for context)
    pub context_before: Vec<String>,
    /// Lines after the match (for context)
    pub context_after: Vec<String>,
}

/// Search results containing all matches
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResults {
    /// All matches found
    pub matches: Vec<SearchMatch>,
    /// Total number of matches
    pub total_matches: usize,
    /// Number of files searched
    pub files_searched: usize,
    /// Number of files with matches
    pub files_with_matches: usize,
    /// Search duration in milliseconds
    pub duration_ms: u64,
}

/// Configuration for search operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchConfig {
    /// The search pattern (can be regex if use_regex is true)
    pub pattern: String,
    /// Whether to use regex matching
    pub use_regex: bool,
    /// Case-insensitive search
    pub case_insensitive: bool,
    /// Maximum number of matches to return (0 = unlimited)
    pub max_matches: usize,
    /// Number of context lines before match
    pub context_before: usize,
    /// Number of context lines after match
    pub context_after: usize,
    /// File extensions to include (e.g., ["rs", "dart"])
    pub include_extensions: Vec<String>,
    /// File extensions to exclude
    pub exclude_extensions: Vec<String>,
    /// Paths to exclude (e.g., ["node_modules", ".git"])
    pub exclude_paths: Vec<String>,
}

impl Default for SearchConfig {
    fn default() -> Self {
        Self {
            pattern: String::new(),
            use_regex: false,
            case_insensitive: false,
            max_matches: 1000,
            context_before: 2,
            context_after: 2,
            include_extensions: vec![],
            exclude_extensions: vec![],
            exclude_paths: vec![
                ".git".to_string(),
                "node_modules".to_string(),
                ".dart_tool".to_string(),
                "build".to_string(),
            ],
        }
    }
}

/// File content for search
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileContent {
    pub path: String,
    pub content: String,
}

/// Main WASM entry point: Search across multiple files
#[wasm_bindgen]
pub fn search_files(
    files_json: &str,
    config_json: &str,
) -> Result<JsValue, JsValue> {
    let start = js_sys::Date::now();

    // Parse inputs
    let files: Vec<FileContent> = serde_json::from_str(files_json)
        .map_err(|e| JsValue::from_str(&format!("Failed to parse files: {}", e)))?;

    let config: SearchConfig = serde_json::from_str(config_json)
        .map_err(|e| JsValue::from_str(&format!("Failed to parse config: {}", e)))?;

    // Perform search
    let results = search_files_internal(&files, &config);

    let duration_ms = (js_sys::Date::now() - start) as u64;
    let results_with_duration = SearchResults {
        duration_ms,
        ..results
    };

    // Serialize results
    serde_wasm_bindgen::to_value(&results_with_duration)
        .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
}

/// Internal search implementation (testable without WASM)
fn search_files_internal(
    files: &[FileContent],
    config: &SearchConfig,
) -> SearchResults {
    let mut all_matches = Vec::new();
    let mut files_with_matches = 0;
    let exclude_paths_set: HashSet<_> = config.exclude_paths.iter().collect();
    let include_extensions_set: HashSet<_> = config.include_extensions.iter().collect();
    let exclude_extensions_set: HashSet<_> = config.exclude_extensions.iter().collect();

    // Compile regex if needed
    let regex = if config.use_regex {
        let pattern = if config.case_insensitive {
            format!("(?i){}", config.pattern)
        } else {
            config.pattern.clone()
        };
        match Regex::new(&pattern) {
            Ok(r) => Some(r),
            Err(_) => return SearchResults {
                matches: vec![],
                total_matches: 0,
                files_searched: 0,
                files_with_matches: 0,
                duration_ms: 0,
            },
        }
    } else {
        None
    };

    let pattern_lower = config.pattern.to_lowercase();

    for file in files {
        // Check if file should be excluded
        if should_exclude_file(&file.path, &exclude_paths_set, &include_extensions_set, &exclude_extensions_set) {
            continue;
        }

        let file_matches = search_file(file, config, &regex, &pattern_lower);

        if !file_matches.is_empty() {
            files_with_matches += 1;
            all_matches.extend(file_matches);
        }

        // Check max matches limit
        if config.max_matches > 0 && all_matches.len() >= config.max_matches {
            all_matches.truncate(config.max_matches);
            break;
        }
    }

    SearchResults {
        total_matches: all_matches.len(),
        matches: all_matches,
        files_searched: files.len(),
        files_with_matches,
        duration_ms: 0, // Will be set by caller
    }
}

/// Search within a single file
fn search_file(
    file: &FileContent,
    config: &SearchConfig,
    regex: &Option<Regex>,
    pattern_lower: &str,
) -> Vec<SearchMatch> {
    let mut matches = Vec::new();
    let lines: Vec<&str> = file.content.lines().collect();

    for (line_idx, line) in lines.iter().enumerate() {
        let line_matches = if let Some(ref re) = regex {
            // Regex search
            find_regex_matches(line, re)
        } else {
            // Plain text search
            find_text_matches(line, &config.pattern, pattern_lower, config.case_insensitive)
        };

        for (column, match_length) in line_matches {
            // Get context lines
            let context_before = get_context_lines(&lines, line_idx, config.context_before, true);
            let context_after = get_context_lines(&lines, line_idx, config.context_after, false);

            matches.push(SearchMatch {
                file_path: file.path.clone(),
                line_number: line_idx + 1, // 1-indexed
                column,
                line_content: line.to_string(),
                match_length,
                context_before,
                context_after,
            });
        }
    }

    matches
}

/// Find all regex matches in a line
fn find_regex_matches(line: &str, regex: &Regex) -> Vec<(usize, usize)> {
    regex
        .find_iter(line)
        .map(|m| (m.start(), m.end() - m.start()))
        .collect()
}

/// Find all plain text matches in a line
fn find_text_matches(
    line: &str,
    pattern: &str,
    pattern_lower: &str,
    case_insensitive: bool,
) -> Vec<(usize, usize)> {
    let mut matches = Vec::new();
    let search_in = if case_insensitive {
        line.to_lowercase()
    } else {
        line.to_string()
    };

    let search_pattern = if case_insensitive {
        pattern_lower
    } else {
        pattern
    };

    let mut start = 0;
    while let Some(pos) = search_in[start..].find(search_pattern) {
        let actual_pos = start + pos;
        matches.push((actual_pos, pattern.len()));
        start = actual_pos + 1; // Continue searching after this match
    }

    matches
}

/// Get context lines before or after a given line
fn get_context_lines(
    lines: &[&str],
    line_idx: usize,
    count: usize,
    before: bool,
) -> Vec<String> {
    if count == 0 {
        return vec![];
    }

    if before {
        let start = line_idx.saturating_sub(count);
        lines[start..line_idx]
            .iter()
            .map(|s| s.to_string())
            .collect()
    } else {
        let end = (line_idx + 1 + count).min(lines.len());
        lines[line_idx + 1..end]
            .iter()
            .map(|s| s.to_string())
            .collect()
    }
}

/// Check if file should be excluded based on path and extension
fn should_exclude_file(
    file_path: &str,
    exclude_paths: &HashSet<&String>,
    include_extensions: &HashSet<&String>,
    exclude_extensions: &HashSet<&String>,
) -> bool {
    // Check excluded paths
    for exclude in exclude_paths {
        if file_path.contains(exclude.as_str()) {
            return true;
        }
    }

    // Get file extension
    let extension = file_path
        .rsplit('.')
        .next()
        .unwrap_or("");

    // Check excluded extensions
    if !exclude_extensions.is_empty() && exclude_extensions.contains(&extension.to_string()) {
        return true;
    }

    // Check included extensions (if specified)
    if !include_extensions.is_empty() && !include_extensions.contains(&extension.to_string()) {
        return true;
    }

    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_plain_text_search() {
        let file = FileContent {
            path: "test.txt".to_string(),
            content: "Hello World\nHello Rust\nGoodbye World".to_string(),
        };

        let config = SearchConfig {
            pattern: "Hello".to_string(),
            use_regex: false,
            case_insensitive: false,
            ..Default::default()
        };

        let matches = search_file(&file, &config, &None, &config.pattern.to_lowercase());
        assert_eq!(matches.len(), 2);
        assert_eq!(matches[0].line_number, 1);
        assert_eq!(matches[1].line_number, 2);
    }

    #[test]
    fn test_case_insensitive_search() {
        let file = FileContent {
            path: "test.txt".to_string(),
            content: "HELLO world\nhello WORLD".to_string(),
        };

        let config = SearchConfig {
            pattern: "hello".to_string(),
            use_regex: false,
            case_insensitive: true,
            ..Default::default()
        };

        let matches = search_file(&file, &config, &None, &"hello".to_string());
        assert_eq!(matches.len(), 2);
    }

    #[test]
    fn test_regex_search() {
        let file = FileContent {
            path: "test.txt".to_string(),
            content: "test123\ntest456\nabc789".to_string(),
        };

        let config = SearchConfig {
            pattern: r"test\d+".to_string(),
            use_regex: true,
            case_insensitive: false,
            ..Default::default()
        };

        let regex = Regex::new(&config.pattern).ok();
        let matches = search_file(&file, &config, &regex, &"".to_string());
        assert_eq!(matches.len(), 2);
    }

    #[test]
    fn test_context_lines() {
        let lines = vec!["line1", "line2", "line3", "line4", "line5"];

        let before = get_context_lines(&lines, 2, 2, true);
        assert_eq!(before, vec!["line1", "line2"]);

        let after = get_context_lines(&lines, 2, 2, false);
        assert_eq!(after, vec!["line4", "line5"]);
    }

    #[test]
    fn test_exclude_paths() {
        let mut exclude = HashSet::new();
        exclude.insert(&"node_modules".to_string());

        assert!(should_exclude_file(
            "src/node_modules/file.js",
            &exclude,
            &HashSet::new(),
            &HashSet::new(),
        ));

        assert!(!should_exclude_file(
            "src/main.js",
            &exclude,
            &HashSet::new(),
            &HashSet::new(),
        ));
    }
}
