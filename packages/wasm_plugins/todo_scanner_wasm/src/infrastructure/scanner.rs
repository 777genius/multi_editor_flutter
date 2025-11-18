// Infrastructure - Regex-based TODO scanner implementation

use regex::Regex;
use crate::domain::{TodoItem, TodoType, Language};
use crate::domain::services::{TodoScanner, extract_author, extract_tags, extract_priority_from_text};

/// Regex-based TODO scanner
pub struct RegexTodoScanner {
    patterns: Vec<(TodoType, Regex)>,
}

impl RegexTodoScanner {
    pub fn new() -> Self {
        // Build regex patterns for all TODO types
        let mut patterns = Vec::new();

        for todo_type in TodoType::all() {
            // Pattern: (//|#|/\*) TODO(author)?: text
            // Matches:
            // - // TODO: fix this
            // - // TODO(john): fix this
            // - # TODO: fix this
            // - /* TODO: fix this */
            let pattern_str = format!(
                r"(?m)^\s*(?://|#|/\*+)\s*{}(?:\([@\w\-]+\))?(?:\[[@\w\-]+\])?[\s:]*(.*)$",
                todo_type.pattern()
            );

            if let Ok(regex) = Regex::new(&pattern_str) {
                patterns.push((todo_type, regex));
            }
        }

        Self { patterns }
    }
}

impl Default for RegexTodoScanner {
    fn default() -> Self {
        Self::new()
    }
}

impl TodoScanner for RegexTodoScanner {
    fn scan(&self, content: &str, _language: &Language) -> Vec<TodoItem> {
        let mut todos = Vec::new();
        let lines: Vec<&str> = content.lines().collect();

        // Scan each line
        for (line_idx, line) in lines.iter().enumerate() {
            // Try each TODO pattern
            for (todo_type, pattern) in &self.patterns {
                if let Some(captures) = pattern.captures(line) {
                    // Extract the comment text (group 1)
                    let text = captures.get(1)
                        .map(|m| m.as_str().trim())
                        .unwrap_or("")
                        .to_string();

                    // Skip empty TODOs
                    if text.is_empty() {
                        continue;
                    }

                    // Find column position of TODO marker
                    let column = line.find(todo_type.display_name())
                        .unwrap_or(0) as u32;

                    // Determine priority
                    let priority = extract_priority_from_text(&text)
                        .unwrap_or_else(|| todo_type.default_priority());

                    // Extract author
                    let author = extract_author(line);

                    // Extract tags
                    let tags = extract_tags(&text);

                    // Create TODO item
                    let mut item = TodoItem::new(
                        todo_type.clone(),
                        priority,
                        text,
                        line_idx as u32,
                        column,
                    );

                    if let Some(auth) = author {
                        item = item.with_author(auth);
                    }

                    if !tags.is_empty() {
                        item = item.with_tags(tags);
                    }

                    todos.push(item);
                    break; // Only match one TODO type per line
                }
            }
        }

        todos
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_scan_simple_todos() {
        let scanner = RegexTodoScanner::new();
        let content = r#"
// TODO: implement this feature
// FIXME: fix the bug
// HACK: temporary workaround
"#;

        let todos = scanner.scan(content, &Language::Dart);
        assert_eq!(todos.len(), 3);
        assert_eq!(todos[0].text, "implement this feature");
        assert_eq!(todos[1].text, "fix the bug");
        assert_eq!(todos[2].text, "temporary workaround");
    }

    #[test]
    fn test_scan_with_author() {
        let scanner = RegexTodoScanner::new();
        let content = "// TODO(john): refactor this code";

        let todos = scanner.scan(content, &Language::Dart);
        assert_eq!(todos.len(), 1);
        assert_eq!(todos[0].author, Some("john".to_string()));
    }

    #[test]
    fn test_scan_with_tags() {
        let scanner = RegexTodoScanner::new();
        let content = "// TODO #bug #critical: fix memory leak";

        let todos = scanner.scan(content, &Language::Dart);
        assert_eq!(todos.len(), 1);
        assert_eq!(todos[0].tags, vec!["bug", "critical"]);
    }

    #[test]
    fn test_scan_with_priority() {
        let scanner = RegexTodoScanner::new();
        let content = "// TODO !!! urgent fix needed";

        let todos = scanner.scan(content, &Language::Dart);
        assert_eq!(todos.len(), 1);
        assert_eq!(todos[0].priority, crate::domain::TodoPriority::High);
    }

    #[test]
    fn test_scan_python_comments() {
        let scanner = RegexTodoScanner::new();
        let content = "# TODO: implement this";

        let todos = scanner.scan(content, &Language::Python);
        assert_eq!(todos.len(), 1);
        assert_eq!(todos[0].text, "implement this");
    }
}
