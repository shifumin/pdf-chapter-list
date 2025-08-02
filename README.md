# pdf-chapter-list

Ruby script to visualize PDF chapter structure

## Overview

This Ruby script extracts and displays the chapter structure (outline/bookmarks) from PDF files in a hierarchical format, including page numbers. It supports two output formats: Markdown list (default) and tree structure. The script handles both English and Japanese PDFs with proper encoding support.

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
bundle exec ruby pdf_chapter_list.rb [options] path/to/your.pdf

# Or make it executable and run directly
chmod +x pdf_chapter_list.rb
./pdf_chapter_list.rb [options] path/to/your.pdf

# Show help
bundle exec ruby pdf_chapter_list.rb -h
```

### Command Line Options

- `-d, --depth LEVEL` - Display only LEVEL levels of hierarchy (default: all levels)
- `-t, --tree` - Display output in tree format instead of Markdown list
- `-i, --indent SPACES` - Set indent spacing (default: 2)
- `-h, --help` - Show help message

### Examples

```bash
# Show all levels in Markdown format (default)
bundle exec ruby pdf_chapter_list.rb document.pdf

# Show all levels in tree format
bundle exec ruby pdf_chapter_list.rb -t document.pdf

# Show only top level chapters
bundle exec ruby pdf_chapter_list.rb -d 1 document.pdf

# Show up to 2 levels deep in tree format
bundle exec ruby pdf_chapter_list.rb -t --depth 2 document.pdf

# Use 4-space indent for Obsidian compatibility
bundle exec ruby pdf_chapter_list.rb -i 4 document.pdf

# Combine 4-space indent with depth limit
bundle exec ruby pdf_chapter_list.rb -i 4 -d 2 document.pdf
```

### Output Formats

#### Markdown Format (default)

The script outputs the PDF's chapter structure as a Markdown list:

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

#### Tree Format

With the `-t` or `--tree` option, the output uses tree-style formatting:

```
document.pdf
├── 1. Introduction (p.1)
│   ├── 1.1 Background (p.3)
│   └── 1.2 Overview (p.7)
├── 2. Getting Started (p.12)
│   ├── 2.1 Installation (p.12)
│   └── 2.2 Configuration (p.15)
└── 3. Advanced Topics (p.20)
```

For Japanese PDFs:

Markdown format:
```markdown
# 技術書.pdf

- 表紙 (p.1)
- 目次 (p.2)
- 第Ⅰ部 基礎知識 (p.5)
  - 1章 はじめに (p.7)
    - 1.1 背景と目的 (p.8)
    - 1.2 本書の構成 (p.10)
  - 2章 環境構築 (p.15)
- 第Ⅱ部 実践編 (p.25)
```

Tree format:
```
技術書.pdf
├── 表紙 (p.1)
├── 目次 (p.2)
├── 第Ⅰ部 基礎知識 (p.5)
│   ├── 1章 はじめに (p.7)
│   │   ├── 1.1 背景と目的 (p.8)
│   │   └── 1.2 本書の構成 (p.10)
│   └── 2章 環境構築 (p.15)
└── 第Ⅱ部 実践編 (p.25)
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
- Two output formats available:
  - Markdown list format (default)
  - Tree structure format (with `-t` option)
- Shows page numbers for each chapter when available
- Supports multiple PDF destination formats:
  - Array-based destinations (standard format)
  - Named destinations like "p35" (O'Reilly and other publishers)
- Handles UTF-16BE encoding (common in Japanese PDFs)
- Properly decodes international characters
- Removes BOM and other invisible characters
- Depth limiting feature to control output hierarchy levels
- Customizable indent spacing for compatibility with different Markdown editors
- Works with both English and Japanese PDFs

### Indent Option for Obsidian

The `-i` or `--indent` option allows you to customize the indentation spacing. This is particularly useful for Obsidian users:

- **Default (2 spaces)**: Standard Markdown indentation
- **4 spaces**: Required by Obsidian for proper nested list rendering
- **Custom**: Any number of spaces based on your preference

Example for Obsidian:
```bash
# Extract chapters with 4-space indent for Obsidian
bundle exec ruby pdf_chapter_list.rb -i 4 document.pdf
```

This ensures that nested lists are properly rendered in Obsidian's editor and preview modes.

## Notes

- The script only works with PDFs that have an outline/bookmark structure
- PDFs without outlines will display a message indicating no chapters were found
- Page numbers are extracted when available in the PDF outline
- The script is executable and can be run directly after making it executable with `chmod +x`
- Supports both English and Japanese PDFs (and other languages with proper Unicode encoding)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
