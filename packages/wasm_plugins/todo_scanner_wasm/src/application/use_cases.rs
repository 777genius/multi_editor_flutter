// Application Use Cases - Business logic orchestration

use std::time::Instant;
use crate::domain::{TodoCollection, TodoTypeCounts, PriorityCounts};
use crate::domain::services::TodoScanner;
use super::dto::{ScanRequest, ScanResponse};

/// Use case for scanning TODOs in source code
pub struct ScanTodosUseCase<S: TodoScanner> {
    scanner: S,
}

impl<S: TodoScanner> ScanTodosUseCase<S> {
    pub fn new(scanner: S) -> Self {
        Self { scanner }
    }

    /// Execute the scan operation
    pub fn execute(&self, request: ScanRequest) -> ScanResponse {
        let start_time = Instant::now();

        // Detect language
        let language = request.detect_language();

        // Scan for TODOs
        let todos = self.scanner.scan(&request.content, &language);

        // Calculate statistics
        let mut counts_by_type = TodoTypeCounts::default();
        let mut counts_by_priority = PriorityCounts::default();

        for todo in &todos {
            counts_by_type.increment(&todo.todo_type);
            counts_by_priority.increment(&todo.priority);
        }

        // Build collection
        let collection = TodoCollection {
            items: todos,
            counts_by_type,
            counts_by_priority,
            scan_duration_ms: start_time.elapsed().as_millis() as u64,
        };

        ScanResponse::success(request.request_id, collection)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::infrastructure::RegexTodoScanner;

    #[test]
    fn test_scan_use_case() {
        let scanner = RegexTodoScanner::new();
        let use_case = ScanTodosUseCase::new(scanner);

        let request = ScanRequest::new(
            "test-1".to_string(),
            "// TODO: implement this\n// FIXME: fix bug".to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        assert!(response.data.is_some());

        let data = response.data.unwrap();
        assert_eq!(data.items.len(), 2);
        assert_eq!(data.counts_by_type.todo, 1);
        assert_eq!(data.counts_by_type.fixme, 1);
    }

    #[test]
    fn test_scan_with_language_detection() {
        let scanner = RegexTodoScanner::new();
        let use_case = ScanTodosUseCase::new(scanner);

        let request = ScanRequest::new(
            "test-2".to_string(),
            "# TODO: implement this".to_string(),
        ).with_file_extension("py".to_string());

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();
        assert_eq!(data.items.len(), 1);
    }
}
