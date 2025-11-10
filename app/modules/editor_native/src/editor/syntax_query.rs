use tree_sitter::{Node, Query, QueryCursor, Tree};
#[cfg(test)]
use tree_sitter::Parser;

/// Syntax tree query utilities.
///
/// Provides high-level API for querying tree-sitter syntax trees:
/// - Find nodes by type
/// - Find nodes by pattern
/// - Navigate tree structure
/// - Extract text from nodes
///
/// This is useful for:
/// - Syntax-aware navigation (next/previous function)
/// - Code analysis (find all function calls)
/// - Refactoring (rename all variable uses)
/// - Semantic selection (expand selection to node)
#[derive(Debug)]
pub struct SyntaxQuery<'a> {
    tree: &'a Tree,
    source: &'a str,
}

impl<'a> SyntaxQuery<'a> {
    /// Creates a new syntax query for a tree.
    pub fn new(tree: &'a Tree, source: &'a str) -> Self {
        Self { tree, source }
    }

    /// Gets the root node of the tree.
    pub fn root(&self) -> Node<'a> {
        self.tree.root_node()
    }

    /// Finds all nodes of a specific type.
    ///
    /// Parameters:
    /// - `node_type`: Type of nodes to find (e.g., "function_definition")
    ///
    /// Returns: Vector of matching nodes
    pub fn find_by_type(&self, node_type: &str) -> Vec<Node<'a>> {
        let mut results = Vec::new();
        self.traverse(self.root(), &mut |node| {
            if node.kind() == node_type {
                results.push(node);
            }
            true // Continue traversal
        });
        results
    }

    /// Finds the innermost node at a specific position.
    ///
    /// Parameters:
    /// - `line`: Line number (0-indexed)
    /// - `column`: Column number (0-indexed)
    ///
    /// Returns: Node at position, or root if not found
    pub fn node_at_position(&self, line: usize, column: usize) -> Node<'a> {
        let point = tree_sitter::Point::new(line, column);
        self.root().descendant_for_point_range(point, point)
            .unwrap_or_else(|| self.root())
    }

    /// Finds nodes matching a tree-sitter query pattern.
    ///
    /// Parameters:
    /// - `pattern`: Tree-sitter query string
    /// - `language`: Tree-sitter language
    ///
    /// Returns: Result with vector of (node, capture_name) tuples
    ///
    /// Example pattern:
    /// ```scm
    /// (function_definition
    ///   name: (identifier) @function.name
    ///   parameters: (parameters) @function.params)
    /// ```
    pub fn find_by_pattern(
        &self,
        pattern: &str,
        language: &tree_sitter::Language,
    ) -> Result<Vec<(Node<'a>, String)>, QueryError> {
        let query = Query::new(*language, pattern)
            .map_err(|e| QueryError::InvalidPattern(e.to_string()))?;

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, self.root(), self.source.as_bytes());

        let mut results = Vec::new();
        for m in matches {
            for capture in m.captures {
                let capture_name = query.capture_names()[capture.index as usize].to_string();
                results.push((capture.node, capture_name));
            }
        }

        Ok(results)
    }

    /// Gets text content of a node.
    ///
    /// Parameters:
    /// - `node`: The node to get text from
    ///
    /// Returns: Text content
    pub fn node_text(&self, node: Node<'a>) -> &'a str {
        node.utf8_text(self.source.as_bytes()).unwrap_or("")
    }

    /// Finds parent node of a specific type.
    ///
    /// Parameters:
    /// - `node`: Starting node
    /// - `parent_type`: Type of parent to find
    ///
    /// Returns: Parent node if found
    pub fn find_parent(&self, node: Node<'a>, parent_type: &str) -> Option<Node<'a>> {
        let mut current = node.parent();
        while let Some(parent) = current {
            if parent.kind() == parent_type {
                return Some(parent);
            }
            current = parent.parent();
        }
        None
    }

    /// Finds next sibling of a specific type.
    ///
    /// Parameters:
    /// - `node`: Starting node
    /// - `sibling_type`: Type of sibling to find
    ///
    /// Returns: Next sibling if found
    pub fn find_next_sibling(&self, node: Node<'a>, sibling_type: &str) -> Option<Node<'a>> {
        let mut current = node.next_sibling();
        while let Some(sibling) = current {
            if sibling.kind() == sibling_type {
                return Some(sibling);
            }
            current = sibling.next_sibling();
        }
        None
    }

    /// Finds previous sibling of a specific type.
    ///
    /// Parameters:
    /// - `node`: Starting node
    /// - `sibling_type`: Type of sibling to find
    ///
    /// Returns: Previous sibling if found
    pub fn find_prev_sibling(&self, node: Node<'a>, sibling_type: &str) -> Option<Node<'a>> {
        let mut current = node.prev_sibling();
        while let Some(sibling) = current {
            if sibling.kind() == sibling_type {
                return Some(sibling);
            }
            current = sibling.prev_sibling();
        }
        None
    }

    /// Gets all children of a node.
    ///
    /// Parameters:
    /// - `node`: Parent node
    ///
    /// Returns: Vector of child nodes
    pub fn children(&self, node: Node<'a>) -> Vec<Node<'a>> {
        let mut cursor = node.walk();
        node.children(&mut cursor).collect()
    }

    /// Gets children of a specific type.
    ///
    /// Parameters:
    /// - `node`: Parent node
    /// - `child_type`: Type of children to find
    ///
    /// Returns: Vector of matching child nodes
    pub fn children_by_type(&self, node: Node<'a>, child_type: &str) -> Vec<Node<'a>> {
        let mut cursor = node.walk();
        node.children(&mut cursor)
            .filter(|child| child.kind() == child_type)
            .collect()
    }

    /// Traverses the syntax tree depth-first.
    ///
    /// Parameters:
    /// - `node`: Starting node
    /// - `visitor`: Callback for each node (return false to stop)
    fn traverse<F>(&self, node: Node<'a>, visitor: &mut F)
    where
        F: FnMut(Node<'a>) -> bool,
    {
        if !visitor(node) {
            return;
        }

        let mut cursor = node.walk();
        for child in node.children(&mut cursor) {
            self.traverse(child, visitor);
        }
    }

    /// Gets start position of a node.
    ///
    /// Parameters:
    /// - `node`: The node
    ///
    /// Returns: (line, column)
    pub fn node_start(&self, node: Node<'a>) -> (usize, usize) {
        let start = node.start_position();
        (start.row, start.column)
    }

    /// Gets end position of a node.
    ///
    /// Parameters:
    /// - `node`: The node
    ///
    /// Returns: (line, column)
    pub fn node_end(&self, node: Node<'a>) -> (usize, usize) {
        let end = node.end_position();
        (end.row, end.column)
    }

    /// Checks if a node contains a position.
    ///
    /// Parameters:
    /// - `node`: The node
    /// - `line`: Line number
    /// - `column`: Column number
    ///
    /// Returns: true if position is inside node
    pub fn contains_position(&self, node: Node<'a>, line: usize, column: usize) -> bool {
        let start = node.start_position();
        let end = node.end_position();

        if line < start.row || line > end.row {
            return false;
        }

        if line == start.row && column < start.column {
            return false;
        }

        if line == end.row && column > end.column {
            return false;
        }

        true
    }
}

/// Query error types.
#[derive(Debug, Clone)]
pub enum QueryError {
    InvalidPattern(String),
}

impl std::fmt::Display for QueryError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            QueryError::InvalidPattern(msg) => write!(f, "Invalid query pattern: {}", msg),
        }
    }
}

impl std::error::Error for QueryError {}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse_python(source: &str) -> Tree {
        let mut parser = Parser::new();
        parser.set_language(tree_sitter_python::language()).unwrap();
        parser.parse(source, None).unwrap()
    }

    #[test]
    fn test_find_by_type() {
        let source = "def foo():\n    pass\n\ndef bar():\n    pass";
        let tree = parse_python(source);
        let query = SyntaxQuery::new(&tree, source);

        let functions = query.find_by_type("function_definition");
        assert_eq!(functions.len(), 2);
    }

    #[test]
    fn test_node_at_position() {
        let source = "def foo():\n    pass";
        let tree = parse_python(source);
        let query = SyntaxQuery::new(&tree, source);

        let node = query.node_at_position(0, 4); // Position of "foo"
        assert_eq!(query.node_text(node), "foo");
    }

    #[test]
    fn test_node_text() {
        let source = "def foo():\n    pass";
        let tree = parse_python(source);
        let query = SyntaxQuery::new(&tree, source);

        let functions = query.find_by_type("function_definition");
        assert_eq!(functions.len(), 1);

        let func_text = query.node_text(functions[0]);
        assert_eq!(func_text, "def foo():\n    pass");
    }

    #[test]
    fn test_children() {
        let source = "def foo(a, b):\n    pass";
        let tree = parse_python(source);
        let query = SyntaxQuery::new(&tree, source);

        let root = query.root();
        let children = query.children(root);
        assert!(!children.is_empty());
    }

    #[test]
    fn test_node_positions() {
        let source = "def foo():\n    pass";
        let tree = parse_python(source);
        let query = SyntaxQuery::new(&tree, source);

        let functions = query.find_by_type("function_definition");
        let func = functions[0];

        let (start_line, start_col) = query.node_start(func);
        assert_eq!(start_line, 0);
        assert_eq!(start_col, 0);

        let (end_line, _) = query.node_end(func);
        assert_eq!(end_line, 1);
    }

    #[test]
    fn test_contains_position() {
        let source = "def foo():\n    pass";
        let tree = parse_python(source);
        let query = SyntaxQuery::new(&tree, source);

        let functions = query.find_by_type("function_definition");
        let func = functions[0];

        assert!(query.contains_position(func, 0, 4));
        assert!(query.contains_position(func, 1, 4));
        assert!(!query.contains_position(func, 2, 0));
    }
}
