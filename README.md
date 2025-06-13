# pdf-chapter-list

Ruby script to visualize PDF chapter structure

## Overview

This Ruby script extracts and displays the chapter structure (outline/bookmarks) from PDF files in a hierarchical Markdown format, including page numbers. It supports both English and Japanese PDFs with proper encoding handling.

## Requirements

- Ruby 3.4 or higher
- Bundler

## Installation

1. Clone this repository:
```bash
git clone https://github.com/shifumin/pdf-chapter-list.git
cd pdf-chapter-list
```

2. Install dependencies:
```bash
bundle install
```

## Usage

```bash
bundle exec ruby pdf_chapter_tree.rb path/to/your.pdf

# Or make it executable and run directly
chmod +x pdf_chapter_tree.rb
./pdf_chapter_tree.rb path/to/your.pdf

# Show help
bundle exec ruby pdf_chapter_tree.rb -h
```

### Example

```bash
bundle exec ruby pdf_chapter_tree.rb document.pdf
```

### Output Format

The script outputs the PDF's chapter structure in Markdown format:

```markdown
# document.pdf

- 1. Introduction (p.1)
  - 1.1 Background (p.3)
  - 1.2 Overview (p.7)
- 2. Getting Started (p.12)
  - 2.1 Installation (p.12)
  - 2.2 Configuration (p.15)
- 3. Advanced Topics (p.20)
```


For Japanese PDFs:

```markdown
# 技術書.pdf

- 表紙 (p.1)
- 目次 (p.2)
- 第Ⅰ部　基礎知識 (p.5)
  - 1章　はじめに (p.7)
    - 1.1　背景と目的 (p.8)
    - 1.2　本書の構成 (p.10)
  - 2章　環境構築 (p.15)
- 第Ⅱ部　実践編 (p.25)
```

## Development

### Running Tests

```bash
bundle exec rspec
```

### Linting

```bash
bundle exec rubocop
```

To auto-correct issues:
```bash
bundle exec rubocop -a
```

### Generating Test PDFs

Test PDFs can be regenerated if needed:
```bash
bundle exec ruby spec/support/generate_test_pdfs.rb
```

## Features

- Extracts PDF outline/bookmark structure
- Displays hierarchical chapter structure in Markdown format
- Shows page numbers for each chapter when available
- Handles UTF-16BE encoding (common in Japanese PDFs)
- Properly decodes international characters
- Removes BOM and other invisible characters

## Notes

- The script only works with PDFs that have an outline/bookmark structure
- PDFs without outlines will display a message indicating no chapters were found
- Page numbers are extracted when available in the PDF outline
- The script is executable and can be run directly after making it executable with `chmod +x`
- Supports both English and Japanese PDFs (and other languages with proper Unicode encoding)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
