use std::time::{Duration, Instant};
use std::collections::VecDeque;

/// Performance metrics for editor operations.
///
/// Tracks operation latency to help identify performance bottlenecks.
#[derive(Debug, Clone)]
pub struct PerformanceMetrics {
    /// Recent operation times (rolling window)
    insert_times: VecDeque<Duration>,
    delete_times: VecDeque<Duration>,
    undo_times: VecDeque<Duration>,
    redo_times: VecDeque<Duration>,

    /// Maximum samples to keep
    max_samples: usize,
}

impl PerformanceMetrics {
    /// Creates a new PerformanceMetrics instance.
    ///
    /// # Panics
    /// Panics if max_samples is 0, as this would create non-functional metrics.
    pub fn new(max_samples: usize) -> Self {
        assert!(max_samples > 0, "max_samples must be greater than 0");

        Self {
            insert_times: VecDeque::with_capacity(max_samples),
            delete_times: VecDeque::with_capacity(max_samples),
            undo_times: VecDeque::with_capacity(max_samples),
            redo_times: VecDeque::with_capacity(max_samples),
            max_samples,
        }
    }

    /// Records an insert operation time.
    pub fn record_insert(&mut self, duration: Duration) {
        Self::add_sample(&mut self.insert_times, duration, self.max_samples);
    }

    /// Records a delete operation time.
    pub fn record_delete(&mut self, duration: Duration) {
        Self::add_sample(&mut self.delete_times, duration, self.max_samples);
    }

    /// Records an undo operation time.
    pub fn record_undo(&mut self, duration: Duration) {
        Self::add_sample(&mut self.undo_times, duration, self.max_samples);
    }

    /// Records a redo operation time.
    pub fn record_redo(&mut self, duration: Duration) {
        Self::add_sample(&mut self.redo_times, duration, self.max_samples);
    }

    /// Gets average insert time.
    pub fn avg_insert_time(&self) -> Option<Duration> {
        Self::calculate_average(&self.insert_times)
    }

    /// Gets average delete time.
    pub fn avg_delete_time(&self) -> Option<Duration> {
        Self::calculate_average(&self.delete_times)
    }

    /// Gets average undo time.
    pub fn avg_undo_time(&self) -> Option<Duration> {
        Self::calculate_average(&self.undo_times)
    }

    /// Gets average redo time.
    pub fn avg_redo_time(&self) -> Option<Duration> {
        Self::calculate_average(&self.redo_times)
    }

    /// Gets p95 (95th percentile) insert time.
    pub fn p95_insert_time(&self) -> Option<Duration> {
        Self::calculate_percentile(&self.insert_times, 95)
    }

    /// Gets p99 (99th percentile) insert time.
    pub fn p99_insert_time(&self) -> Option<Duration> {
        Self::calculate_percentile(&self.insert_times, 99)
    }

    /// Clears all metrics.
    pub fn clear(&mut self) {
        self.insert_times.clear();
        self.delete_times.clear();
        self.undo_times.clear();
        self.redo_times.clear();
    }

    /// Adds a sample to a rolling window.
    fn add_sample(samples: &mut VecDeque<Duration>, duration: Duration, max_samples: usize) {
        if samples.len() >= max_samples {
            samples.pop_front();
        }
        samples.push_back(duration);
    }

    /// Calculates average duration.
    fn calculate_average(samples: &VecDeque<Duration>) -> Option<Duration> {
        if samples.is_empty() {
            return None;
        }

        let sum: Duration = samples.iter().sum();
        Some(sum / samples.len() as u32)
    }

    /// Calculates percentile (e.g., 95 for p95).
    fn calculate_percentile(samples: &VecDeque<Duration>, percentile: u8) -> Option<Duration> {
        if samples.is_empty() {
            return None;
        }

        let mut sorted: Vec<Duration> = samples.iter().copied().collect();
        sorted.sort();

        let index = (sorted.len() * percentile as usize) / 100;
        sorted.get(index.saturating_sub(1)).copied()
    }
}

impl Default for PerformanceMetrics {
    fn default() -> Self {
        Self::new(100) // Keep last 100 samples by default
    }
}

/// Timer for measuring operation performance.
pub struct OperationTimer {
    start: Instant,
}

impl OperationTimer {
    pub fn start() -> Self {
        Self {
            start: Instant::now(),
        }
    }

    pub fn elapsed(&self) -> Duration {
        self.start.elapsed()
    }
}

/// Performance statistics summary.
#[derive(Debug, Clone)]
pub struct PerformanceStats {
    pub avg_insert_ms: f64,
    pub avg_delete_ms: f64,
    pub avg_undo_ms: f64,
    pub avg_redo_ms: f64,
    pub p95_insert_ms: f64,
    pub p99_insert_ms: f64,
}

impl PerformanceMetrics {
    /// Gets a summary of all performance statistics.
    pub fn get_stats(&self) -> PerformanceStats {
        PerformanceStats {
            avg_insert_ms: self.avg_insert_time()
                .map(|d| d.as_secs_f64() * 1000.0)
                .unwrap_or(0.0),
            avg_delete_ms: self.avg_delete_time()
                .map(|d| d.as_secs_f64() * 1000.0)
                .unwrap_or(0.0),
            avg_undo_ms: self.avg_undo_time()
                .map(|d| d.as_secs_f64() * 1000.0)
                .unwrap_or(0.0),
            avg_redo_ms: self.avg_redo_time()
                .map(|d| d.as_secs_f64() * 1000.0)
                .unwrap_or(0.0),
            p95_insert_ms: self.p95_insert_time()
                .map(|d| d.as_secs_f64() * 1000.0)
                .unwrap_or(0.0),
            p99_insert_ms: self.p99_insert_time()
                .map(|d| d.as_secs_f64() * 1000.0)
                .unwrap_or(0.0),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::thread;

    #[test]
    fn test_performance_metrics_recording() {
        let mut metrics = PerformanceMetrics::new(10);

        metrics.record_insert(Duration::from_millis(5));
        metrics.record_insert(Duration::from_millis(10));
        metrics.record_insert(Duration::from_millis(15));

        let avg = metrics.avg_insert_time().unwrap();
        assert_eq!(avg.as_millis(), 10);
    }

    #[test]
    fn test_performance_metrics_rolling_window() {
        let mut metrics = PerformanceMetrics::new(2);

        metrics.record_insert(Duration::from_millis(5));
        metrics.record_insert(Duration::from_millis(10));
        metrics.record_insert(Duration::from_millis(15)); // Should evict 5ms

        let avg = metrics.avg_insert_time().unwrap();
        assert_eq!(avg.as_millis(), 12); // (10 + 15) / 2 = 12.5 ≈ 12
    }

    #[test]
    fn test_percentile_calculation() {
        let mut metrics = PerformanceMetrics::new(100);

        // Add 100 samples from 1ms to 100ms
        for i in 1..=100 {
            metrics.record_insert(Duration::from_millis(i));
        }

        let p95 = metrics.p95_insert_time().unwrap();
        let p99 = metrics.p99_insert_time().unwrap();

        assert!(p95.as_millis() >= 90 && p95.as_millis() <= 100);
        assert!(p99.as_millis() >= 95 && p99.as_millis() <= 100);
    }

    #[test]
    fn test_operation_timer() {
        let timer = OperationTimer::start();
        thread::sleep(Duration::from_millis(10));
        let elapsed = timer.elapsed();

        assert!(elapsed.as_millis() >= 10);
    }

    #[test]
    fn test_performance_stats() {
        let mut metrics = PerformanceMetrics::new(10);

        metrics.record_insert(Duration::from_millis(5));
        metrics.record_delete(Duration::from_millis(3));

        let stats = metrics.get_stats();

        assert_eq!(stats.avg_insert_ms, 5.0);
        assert_eq!(stats.avg_delete_ms, 3.0);
    }
}
