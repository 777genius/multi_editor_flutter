use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;
use anyhow::{Result, anyhow};
use tracing::{info, warn};

use crate::servers::LspServerInstance;

/// Manages LSP server instances for different languages.
///
/// This is the core component that:
/// - Starts/stops LSP server processes
/// - Routes requests to appropriate servers
/// - Manages server lifecycle
#[derive(Clone)]
pub struct LspManager {
    servers: Arc<RwLock<HashMap<String, LspServerInstance>>>,
}

impl LspManager {
    pub fn new() -> Self {
        Self {
            servers: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Initializes an LSP server for a language
    pub async fn initialize_server(
        &self,
        language_id: &str,
        root_uri: &str,
    ) -> Result<String> {
        let session_id = Uuid::new_v4().to_string();

        info!("Initializing LSP server for language: {}, session: {}", language_id, session_id);

        // Create LSP server instance based on language
        let server = LspServerInstance::create(language_id, root_uri).await?;

        // Store server instance
        let mut servers = self.servers.write().await;
        servers.insert(session_id.clone(), server);

        info!("LSP server initialized successfully: {}", session_id);
        Ok(session_id)
    }

    /// Shuts down an LSP server
    pub async fn shutdown_server(&self, session_id: &str) -> Result<()> {
        info!("Shutting down LSP server: {}", session_id);

        let mut servers = self.servers.write().await;

        if let Some(mut server) = servers.remove(session_id) {
            server.shutdown().await?;
            info!("LSP server shut down successfully: {}", session_id);
            Ok(())
        } else {
            warn!("LSP server not found: {}", session_id);
            Err(anyhow!("Session not found"))
        }
    }

    /// Sends a request to an LSP server
    pub async fn send_request(
        &self,
        session_id: &str,
        method: &str,
        params: serde_json::Value,
    ) -> Result<serde_json::Value> {
        let servers = self.servers.read().await;

        if let Some(server) = servers.get(session_id) {
            server.send_request(method, params).await
        } else {
            Err(anyhow!("Session not found: {}", session_id))
        }
    }

    /// Sends a notification to an LSP server
    pub async fn send_notification(
        &self,
        session_id: &str,
        method: &str,
        params: serde_json::Value,
    ) -> Result<()> {
        let servers = self.servers.read().await;

        if let Some(server) = servers.get(session_id) {
            server.send_notification(method, params).await
        } else {
            Err(anyhow!("Session not found: {}", session_id))
        }
    }

    /// Gets active session count
    #[allow(dead_code)]
    pub async fn session_count(&self) -> usize {
        let servers = self.servers.read().await;
        servers.len()
    }
}

impl Default for LspManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lsp_manager_new() {
        let manager = LspManager::new();
        // Manager should be created successfully
        // Can't directly check servers map, but creation should not panic
    }

    #[test]
    fn test_lsp_manager_default() {
        let manager = LspManager::default();
        // Default should work same as new()
    }

    #[tokio::test]
    async fn test_session_count_initially_zero() {
        let manager = LspManager::new();
        assert_eq!(manager.session_count().await, 0);
    }

    #[tokio::test]
    async fn test_shutdown_nonexistent_session() {
        let manager = LspManager::new();
        let result = manager.shutdown_server("nonexistent-session-id").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_send_request_nonexistent_session() {
        let manager = LspManager::new();
        let result = manager
            .send_request("nonexistent", "test-method", serde_json::json!({}))
            .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_send_notification_nonexistent_session() {
        let manager = LspManager::new();
        let result = manager
            .send_notification("nonexistent", "test-method", serde_json::json!({}))
            .await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_manager_clone() {
        let manager = LspManager::new();
        let cloned = manager.clone();

        // Both should point to same underlying data
        assert_eq!(manager.session_count().await, cloned.session_count().await);
    }
}
