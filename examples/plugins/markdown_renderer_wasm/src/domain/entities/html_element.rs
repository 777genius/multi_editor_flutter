/// HTML Element (Entity)
///
/// Represents a rendered HTML element with metadata.
/// Used for structured HTML output with source mapping.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HtmlElement {
    /// Unique element identifier
    element_id: String,

    /// HTML tag name (e.g., "p", "h1", "code")
    tag_name: String,

    /// HTML content
    content: String,

    /// Source markdown line number (for mapping)
    source_line: Option<usize>,

    /// Element attributes (e.g., "class", "id")
    attributes: Vec<(String, String)>,
}

impl HtmlElement {
    /// Create new HTML element
    pub fn new(
        element_id: String,
        tag_name: String,
        content: String,
    ) -> Self {
        Self {
            element_id,
            tag_name,
            content,
            source_line: None,
            attributes: Vec::new(),
        }
    }

    /// Set source line mapping
    pub fn with_source_line(mut self, line: usize) -> Self {
        self.source_line = Some(line);
        self
    }

    /// Add attribute
    pub fn with_attribute(mut self, key: String, value: String) -> Self {
        self.attributes.push((key, value));
        self
    }

    /// Add multiple attributes
    pub fn with_attributes(mut self, attrs: Vec<(String, String)>) -> Self {
        self.attributes.extend(attrs);
        self
    }

    // Getters
    pub fn element_id(&self) -> &str {
        &self.element_id
    }

    pub fn tag_name(&self) -> &str {
        &self.tag_name
    }

    pub fn content(&self) -> &str {
        &self.content
    }

    pub fn source_line(&self) -> Option<usize> {
        self.source_line
    }

    pub fn attributes(&self) -> &[(String, String)] {
        &self.attributes
    }

    /// Render to HTML string
    pub fn to_html(&self) -> String {
        let mut html = format!("<{}", self.tag_name);

        // Add attributes
        for (key, value) in &self.attributes {
            html.push_str(&format!(" {}=\"{}\"", key, value));
        }

        html.push('>');
        html.push_str(&self.content);
        html.push_str(&format!("</{}>", self.tag_name));

        html
    }
}

/// HTML Element Collection (Aggregate)
///
/// Collection of HTML elements that maintains order and provides operations.
#[derive(Debug, Clone)]
pub struct HtmlElementCollection {
    elements: Vec<HtmlElement>,
}

impl HtmlElementCollection {
    /// Create new empty collection
    pub fn new() -> Self {
        Self {
            elements: Vec::new(),
        }
    }

    /// Add element to collection
    pub fn add(&mut self, element: HtmlElement) {
        self.elements.push(element);
    }

    /// Get all elements
    pub fn elements(&self) -> &[HtmlElement] {
        &self.elements
    }

    /// Get element count
    pub fn len(&self) -> usize {
        self.elements.len()
    }

    /// Check if empty
    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
    }

    /// Render all elements to HTML
    pub fn to_html(&self) -> String {
        self.elements
            .iter()
            .map(|e| e.to_html())
            .collect::<Vec<_>>()
            .join("\n")
    }
}

impl Default for HtmlElementCollection {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_html_element() {
        let elem = HtmlElement::new(
            "elem-1".to_string(),
            "p".to_string(),
            "Hello".to_string(),
        )
        .with_attribute("class".to_string(), "text".to_string());

        assert_eq!(elem.tag_name(), "p");
        assert_eq!(elem.content(), "Hello");
        assert_eq!(elem.to_html(), "<p class=\"text\">Hello</p>");
    }

    #[test]
    fn test_element_collection() {
        let mut collection = HtmlElementCollection::new();

        collection.add(HtmlElement::new(
            "1".to_string(),
            "h1".to_string(),
            "Title".to_string(),
        ));

        collection.add(HtmlElement::new(
            "2".to_string(),
            "p".to_string(),
            "Text".to_string(),
        ));

        assert_eq!(collection.len(), 2);
        let html = collection.to_html();
        assert!(html.contains("<h1>"));
        assert!(html.contains("<p>"));
    }
}
