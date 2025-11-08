use anyhow::{Result, anyhow};
use serde_json::Value;
use std::process::Stdio;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::process::{Child, ChildStdin, ChildStdout, Command};
use tokio::sync::Mutex;
use tracing::{info, error};

/// Represents an LSP server instance for a specific language.
///
/// This manages:
/// - The LSP server process (child process)
/// - Communication via stdin/stdout
/// - JSON-RPC protocol handling
pub struct LspServerInstance {
    #[allow(dead_code)]
    language: String,
    process: Mutex<Child>,
    stdin: Mutex<ChildStdin>,
    stdout: Mutex<BufReader<ChildStdout>>,
}

impl LspServerInstance {
    /// Creates a new LSP server instance for a language
    pub async fn create(language_id: &str, root_uri: &str) -> Result<Self> {
        info!("Creating LSP server for language: {}", language_id);

        // Get LSP server command based on language
        let (cmd, args) = get_lsp_command(language_id)?;

        // Spawn LSP server process
        let mut process = Command::new(cmd)
            .args(&args)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?;

        let stdin = process.stdin.take().ok_or_else(|| anyhow!("Failed to get stdin"))?;
        let stdout = process.stdout.take().ok_or_else(|| anyhow!("Failed to get stdout"))?;

        let instance = Self {
            language: language_id.to_string(),
            process: Mutex::new(process),
            stdin: Mutex::new(stdin),
            stdout: Mutex::new(BufReader::new(stdout)),
        };

        // Send initialize request
        instance.initialize_lsp(root_uri).await?;

        Ok(instance)
    }

    /// Sends LSP initialize request
    async fn initialize_lsp(&self, root_uri: &str) -> Result<()> {
        let init_request = serde_json::json!({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "processId": std::process::id(),
                "rootUri": root_uri,
                "capabilities": {}
            }
        });

        self.send_lsp_message(&init_request).await?;

        // Wait for initialize response
        let _response = self.read_lsp_message().await?;

        // Send initialized notification
        let initialized = serde_json::json!({
            "jsonrpc": "2.0",
            "method": "initialized",
            "params": {}
        });

        self.send_lsp_message(&initialized).await?;

        Ok(())
    }

    /// Sends a request to the LSP server
    pub async fn send_request(&self, method: &str, params: Value) -> Result<Value> {
        let request = serde_json::json!({
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params
        });

        self.send_lsp_message(&request).await?;
        let response = self.read_lsp_message().await?;

        Ok(response.get("result").cloned().unwrap_or(Value::Null))
    }

    /// Sends a notification to the LSP server
    pub async fn send_notification(&self, method: &str, params: Value) -> Result<()> {
        let notification = serde_json::json!({
            "jsonrpc": "2.0",
            "method": method,
            "params": params
        });

        self.send_lsp_message(&notification).await
    }

    /// Sends an LSP message (JSON-RPC via Content-Length header)
    async fn send_lsp_message(&self, message: &Value) -> Result<()> {
        let content = serde_json::to_string(message)?;
        let msg = format!("Content-Length: {}\r\n\r\n{}", content.len(), content);

        let mut stdin = self.stdin.lock().await;
        stdin.write_all(msg.as_bytes()).await?;
        stdin.flush().await?;

        Ok(())
    }

    /// Reads an LSP message
    async fn read_lsp_message(&self) -> Result<Value> {
        let mut stdout = self.stdout.lock().await;

        // Read Content-Length header
        let mut header = String::new();
        stdout.read_line(&mut header).await?;

        if !header.starts_with("Content-Length:") {
            return Err(anyhow!("Invalid LSP message header"));
        }

        let content_length: usize = header
            .trim_start_matches("Content-Length:")
            .trim()
            .parse()?;

        // Read empty line
        let mut empty = String::new();
        stdout.read_line(&mut empty).await?;

        // Read content
        let mut buffer = vec![0u8; content_length];
        tokio::io::AsyncReadExt::read_exact(&mut *stdout, &mut buffer).await?;

        let message = String::from_utf8(buffer)?;
        let value: Value = serde_json::from_str(&message)?;

        Ok(value)
    }

    /// Shuts down the LSP server
    pub async fn shutdown(&mut self) -> Result<()> {
        // Send shutdown request
        let shutdown_request = serde_json::json!({
            "jsonrpc": "2.0",
            "id": 999,
            "method": "shutdown",
            "params": null
        });

        if let Err(e) = self.send_lsp_message(&shutdown_request).await {
            error!("Failed to send shutdown request: {:?}", e);
        }

        // Kill process
        let mut process = self.process.lock().await;
        if let Err(e) = process.kill().await {
            error!("Failed to kill LSP process: {:?}", e);
        }

        Ok(())
    }
}

/// Gets the LSP server command for a language
fn get_lsp_command(language_id: &str) -> Result<(String, Vec<String>)> {
    match language_id {
        "dart" => {
            // Dart Analysis Server
            Ok(("dart".to_string(), vec!["language-server".to_string()]))
        }
        "typescript" | "javascript" => {
            // TypeScript Language Server
            Ok(("typescript-language-server".to_string(), vec!["--stdio".to_string()]))
        }
        "python" => {
            // Python Language Server
            Ok(("pylsp".to_string(), vec![]))
        }
        "rust" => {
            // Rust Analyzer
            Ok(("rust-analyzer".to_string(), vec![]))
        }
        _ => Err(anyhow!("Unsupported language: {}", language_id)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================
    // Language Command Tests
    // ============================================================

    #[test]
    fn test_get_lsp_command_dart() {
        let result = get_lsp_command("dart");
        assert!(result.is_ok());
        let (cmd, args) = result.unwrap();
        assert_eq!(cmd, "dart");
        assert_eq!(args, vec!["language-server"]);
    }

    #[test]
    fn test_get_lsp_command_typescript() {
        let result = get_lsp_command("typescript");
        assert!(result.is_ok());
        let (cmd, args) = result.unwrap();
        assert_eq!(cmd, "typescript-language-server");
        assert_eq!(args, vec!["--stdio"]);
    }

    #[test]
    fn test_get_lsp_command_javascript() {
        let result = get_lsp_command("javascript");
        assert!(result.is_ok());
        let (cmd, args) = result.unwrap();
        assert_eq!(cmd, "typescript-language-server");
        assert_eq!(args, vec!["--stdio"]);
    }

    #[test]
    fn test_get_lsp_command_python() {
        let result = get_lsp_command("python");
        assert!(result.is_ok());
        let (cmd, args) = result.unwrap();
        assert_eq!(cmd, "pylsp");
        assert!(args.is_empty());
    }

    #[test]
    fn test_get_lsp_command_rust() {
        let result = get_lsp_command("rust");
        assert!(result.is_ok());
        let (cmd, args) = result.unwrap();
        assert_eq!(cmd, "rust-analyzer");
        assert!(args.is_empty());
    }

    #[test]
    fn test_get_lsp_command_unsupported() {
        let result = get_lsp_command("unknown_language");
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Unsupported language"));
    }

    #[test]
    fn test_get_lsp_command_empty_string() {
        let result = get_lsp_command("");
        assert!(result.is_err());
    }

    // Note: LspServerInstance tests would require mocking LSP servers
    // which is complex. These tests verify the command selection logic.
}
