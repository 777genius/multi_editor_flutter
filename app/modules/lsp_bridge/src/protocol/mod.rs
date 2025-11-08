use anyhow::Result;
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use tokio_tungstenite::{WebSocketStream, tungstenite::Message};
use tracing::{info, error, warn};

use crate::lsp_manager::LspManager;

/// JSON-RPC request from Flutter client
#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct JsonRpcRequest {
    jsonrpc: String,
    id: Option<Value>,
    method: String,
    params: Option<Value>,
}

/// JSON-RPC response to Flutter client
#[derive(Debug, Serialize)]
struct JsonRpcResponse {
    jsonrpc: String,
    id: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<JsonRpcError>,
}

#[derive(Debug, Serialize)]
struct JsonRpcError {
    code: i32,
    message: String,
}

/// Handles a client WebSocket connection
pub async fn handle_client_connection<S>(
    ws_stream: WebSocketStream<S>,
    lsp_manager: LspManager,
) -> Result<()>
where
    S: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin,
{
    let (mut write, mut read) = ws_stream.split();

    while let Some(message) = read.next().await {
        match message {
            Ok(Message::Text(text)) => {
                info!("Received message: {}", text);

                // Parse JSON-RPC request
                match serde_json::from_str::<JsonRpcRequest>(&text) {
                    Ok(request) => {
                        let response = handle_request(request, &lsp_manager).await;

                        // Send response
                        let response_json = serde_json::to_string(&response)?;
                        write.send(Message::Text(response_json)).await?;
                    }
                    Err(e) => {
                        error!("Failed to parse JSON-RPC request: {:?}", e);

                        let error_response = JsonRpcResponse {
                            jsonrpc: "2.0".to_string(),
                            id: Value::Null,
                            result: None,
                            error: Some(JsonRpcError {
                                code: -32700,
                                message: "Parse error".to_string(),
                            }),
                        };

                        let response_json = serde_json::to_string(&error_response)?;
                        write.send(Message::Text(response_json)).await?;
                    }
                }
            }
            Ok(Message::Close(_)) => {
                info!("Client closed connection");
                break;
            }
            Ok(Message::Ping(data)) => {
                write.send(Message::Pong(data)).await?;
            }
            Err(e) => {
                error!("WebSocket error: {:?}", e);
                break;
            }
            _ => {}
        }
    }

    Ok(())
}

/// Handles a single JSON-RPC request
async fn handle_request(
    request: JsonRpcRequest,
    lsp_manager: &LspManager,
) -> JsonRpcResponse {
    let id = request.id.unwrap_or(Value::Null);

    match request.method.as_str() {
        "initialize" => handle_initialize(id, request.params, lsp_manager).await,
        "shutdown" => handle_shutdown(id, request.params, lsp_manager).await,
        "textDocument/completion" => {
            handle_completion(id, request.params, lsp_manager).await
        }
        "textDocument/hover" => handle_hover(id, request.params, lsp_manager).await,
        "textDocument/didOpen" => {
            handle_did_open(id, request.params, lsp_manager).await
        }
        "textDocument/didChange" => {
            handle_did_change(id, request.params, lsp_manager).await
        }
        _ => {
            warn!("Unsupported method: {}", request.method);
            JsonRpcResponse {
                jsonrpc: "2.0".to_string(),
                id,
                result: None,
                error: Some(JsonRpcError {
                    code: -32601,
                    message: format!("Method not found: {}", request.method),
                }),
            }
        }
    }
}

async fn handle_initialize(
    id: Value,
    params: Option<Value>,
    lsp_manager: &LspManager,
) -> JsonRpcResponse {
    if let Some(params) = params {
        if let (Some(language_id), Some(root_uri)) = (
            params.get("languageId").and_then(|v| v.as_str()),
            params.get("rootUri").and_then(|v| v.as_str()),
        ) {
            match lsp_manager.initialize_server(language_id, root_uri).await {
                Ok(session_id) => {
                    return JsonRpcResponse {
                        jsonrpc: "2.0".to_string(),
                        id,
                        result: Some(serde_json::json!({
                            "sessionId": session_id,
                            "capabilities": {}
                        })),
                        error: None,
                    };
                }
                Err(e) => {
                    error!("Failed to initialize LSP server: {:?}", e);
                }
            }
        }
    }

    JsonRpcResponse {
        jsonrpc: "2.0".to_string(),
        id,
        result: None,
        error: Some(JsonRpcError {
            code: -32602,
            message: "Invalid params".to_string(),
        }),
    }
}

async fn handle_shutdown(
    id: Value,
    params: Option<Value>,
    lsp_manager: &LspManager,
) -> JsonRpcResponse {
    if let Some(params) = params {
        if let Some(session_id) = params.get("sessionId").and_then(|v| v.as_str()) {
            match lsp_manager.shutdown_server(session_id).await {
                Ok(_) => {
                    return JsonRpcResponse {
                        jsonrpc: "2.0".to_string(),
                        id,
                        result: Some(Value::Null),
                        error: None,
                    };
                }
                Err(e) => {
                    error!("Failed to shutdown LSP server: {:?}", e);
                }
            }
        }
    }

    JsonRpcResponse {
        jsonrpc: "2.0".to_string(),
        id,
        result: None,
        error: Some(JsonRpcError {
            code: -32602,
            message: "Invalid params".to_string(),
        }),
    }
}

async fn handle_completion(
    id: Value,
    params: Option<Value>,
    lsp_manager: &LspManager,
) -> JsonRpcResponse {
    if let Some(params) = params {
        if let Some(session_id) = params.get("sessionId").and_then(|v| v.as_str()) {
            // Extract LSP params
            let lsp_params = serde_json::json!({
                "textDocument": params.get("textDocument"),
                "position": params.get("position"),
            });

            match lsp_manager
                .send_request(session_id, "textDocument/completion", lsp_params)
                .await
            {
                Ok(result) => {
                    return JsonRpcResponse {
                        jsonrpc: "2.0".to_string(),
                        id,
                        result: Some(result),
                        error: None,
                    };
                }
                Err(e) => {
                    error!("LSP completion request failed: {:?}", e);
                }
            }
        }
    }

    JsonRpcResponse {
        jsonrpc: "2.0".to_string(),
        id,
        result: None,
        error: Some(JsonRpcError {
            code: -32603,
            message: "Internal error".to_string(),
        }),
    }
}

async fn handle_hover(
    id: Value,
    _params: Option<Value>,
    _lsp_manager: &LspManager,
) -> JsonRpcResponse {
    // Similar to handle_completion
    JsonRpcResponse {
        jsonrpc: "2.0".to_string(),
        id,
        result: Some(Value::Null),
        error: None,
    }
}

async fn handle_did_open(
    id: Value,
    params: Option<Value>,
    lsp_manager: &LspManager,
) -> JsonRpcResponse {
    if let Some(params) = params {
        if let Some(session_id) = params.get("sessionId").and_then(|v| v.as_str()) {
            let lsp_params = serde_json::json!({
                "textDocument": params.get("textDocument"),
            });

            if let Err(e) = lsp_manager
                .send_notification(session_id, "textDocument/didOpen", lsp_params)
                .await
            {
                error!("LSP didOpen notification failed: {:?}", e);
            }
        }
    }

    JsonRpcResponse {
        jsonrpc: "2.0".to_string(),
        id,
        result: Some(Value::Null),
        error: None,
    }
}

async fn handle_did_change(
    id: Value,
    _params: Option<Value>,
    _lsp_manager: &LspManager,
) -> JsonRpcResponse {
    // Similar to handle_did_open
    JsonRpcResponse {
        jsonrpc: "2.0".to_string(),
        id,
        result: Some(Value::Null),
        error: None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================
    // JSON-RPC Request/Response Tests
    // ============================================================

    #[test]
    fn test_parse_jsonrpc_request_valid() {
        let json = r#"{
            "jsonrpc": "2.0",
            "id": 1,
            "method": "test",
            "params": {"key": "value"}
        }"#;

        let request: Result<JsonRpcRequest, _> = serde_json::from_str(json);
        assert!(request.is_ok());

        let request = request.unwrap();
        assert_eq!(request.jsonrpc, "2.0");
        assert_eq!(request.method, "test");
        assert!(request.id.is_some());
        assert!(request.params.is_some());
    }

    #[test]
    fn test_parse_jsonrpc_request_no_params() {
        let json = r#"{
            "jsonrpc": "2.0",
            "id": 1,
            "method": "test"
        }"#;

        let request: Result<JsonRpcRequest, _> = serde_json::from_str(json);
        assert!(request.is_ok());

        let request = request.unwrap();
        assert!(request.params.is_none());
    }

    #[test]
    fn test_parse_jsonrpc_request_no_id() {
        let json = r#"{
            "jsonrpc": "2.0",
            "method": "notification"
        }"#;

        let request: Result<JsonRpcRequest, _> = serde_json::from_str(json);
        assert!(request.is_ok());

        let request = request.unwrap();
        assert!(request.id.is_none());
    }

    #[test]
    fn test_parse_jsonrpc_request_invalid() {
        let json = r#"{"invalid": "json"}"#;
        let request: Result<JsonRpcRequest, _> = serde_json::from_str(json);
        assert!(request.is_err());
    }

    #[test]
    fn test_serialize_jsonrpc_response_success() {
        let response = JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: Value::Number(1.into()),
            result: Some(serde_json::json!({"status": "ok"})),
            error: None,
        };

        let json = serde_json::to_string(&response);
        assert!(json.is_ok());

        let json = json.unwrap();
        assert!(json.contains("\"jsonrpc\":\"2.0\""));
        assert!(json.contains("\"id\":1"));
        assert!(json.contains("\"result\""));
        assert!(!json.contains("\"error\""));
    }

    #[test]
    fn test_serialize_jsonrpc_response_error() {
        let response = JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: Value::Number(1.into()),
            result: None,
            error: Some(JsonRpcError {
                code: -32600,
                message: "Invalid Request".to_string(),
            }),
        };

        let json = serde_json::to_string(&response);
        assert!(json.is_ok());

        let json = json.unwrap();
        assert!(json.contains("\"error\""));
        assert!(json.contains("-32600"));
        assert!(json.contains("Invalid Request"));
        assert!(!json.contains("\"result\""));
    }

    #[test]
    fn test_serialize_jsonrpc_error() {
        let error = JsonRpcError {
            code: -32700,
            message: "Parse error".to_string(),
        };

        let json = serde_json::to_string(&error);
        assert!(json.is_ok());

        let json = json.unwrap();
        assert!(json.contains("-32700"));
        assert!(json.contains("Parse error"));
    }

    // ============================================================
    // Handler Tests
    // ============================================================

    #[tokio::test]
    async fn test_handle_request_unsupported_method() {
        let lsp_manager = LspManager::new();

        let request = JsonRpcRequest {
            jsonrpc: "2.0".to_string(),
            id: Some(Value::Number(1.into())),
            method: "unsupported_method".to_string(),
            params: None,
        };

        let response = handle_request(request, &lsp_manager).await;

        assert!(response.error.is_some());
        let error = response.error.unwrap();
        assert_eq!(error.code, -32601); // Method not found
        assert!(error.message.contains("Method not found"));
    }

    #[tokio::test]
    async fn test_handle_initialize_invalid_params() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());
        let params = Some(serde_json::json!({})); // Missing languageId and rootUri

        let response = handle_initialize(id, params, &lsp_manager).await;

        assert!(response.error.is_some());
        let error = response.error.unwrap();
        assert_eq!(error.code, -32602); // Invalid params
    }

    #[tokio::test]
    async fn test_handle_initialize_no_params() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());

        let response = handle_initialize(id, None, &lsp_manager).await;

        assert!(response.error.is_some());
        let error = response.error.unwrap();
        assert_eq!(error.code, -32602);
    }

    #[tokio::test]
    async fn test_handle_shutdown_no_params() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());

        let response = handle_shutdown(id, None, &lsp_manager).await;

        assert!(response.error.is_some());
        let error = response.error.unwrap();
        assert_eq!(error.code, -32602);
    }

    #[tokio::test]
    async fn test_handle_shutdown_nonexistent_session() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());
        let params = Some(serde_json::json!({
            "sessionId": "nonexistent-session"
        }));

        let response = handle_shutdown(id, params, &lsp_manager).await;

        // Should get error because session doesn't exist
        assert!(response.error.is_some());
    }

    #[tokio::test]
    async fn test_handle_completion_no_session_id() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());
        let params = Some(serde_json::json!({}));

        let response = handle_completion(id, params, &lsp_manager).await;

        assert!(response.error.is_some());
        let error = response.error.unwrap();
        assert_eq!(error.code, -32603); // Internal error
    }

    #[tokio::test]
    async fn test_handle_hover_returns_success() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());
        let params = Some(serde_json::json!({}));

        let response = handle_hover(id, params, &lsp_manager).await;

        // Current implementation returns null result
        assert!(response.result.is_some());
        assert!(response.error.is_none());
    }

    #[tokio::test]
    async fn test_handle_did_open_no_session() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());
        let params = Some(serde_json::json!({}));

        let response = handle_did_open(id, params, &lsp_manager).await;

        // Should still return success (notification)
        assert!(response.result.is_some());
        assert!(response.error.is_none());
    }

    #[tokio::test]
    async fn test_handle_did_change_returns_success() {
        let lsp_manager = LspManager::new();
        let id = Value::Number(1.into());
        let params = Some(serde_json::json!({}));

        let response = handle_did_change(id, params, &lsp_manager).await;

        assert!(response.result.is_some());
        assert!(response.error.is_none());
    }

    #[test]
    fn test_jsonrpc_response_id_types() {
        // Test with different id types
        let response1 = JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: Value::Number(1.into()),
            result: Some(Value::Null),
            error: None,
        };

        let response2 = JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: Value::String("id-string".to_string()),
            result: Some(Value::Null),
            error: None,
        };

        let response3 = JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            id: Value::Null,
            result: Some(Value::Null),
            error: None,
        };

        // All should serialize successfully
        assert!(serde_json::to_string(&response1).is_ok());
        assert!(serde_json::to_string(&response2).is_ok());
        assert!(serde_json::to_string(&response3).is_ok());
    }
}
