#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pdf-reader'

class PDFChapterTree
  def initialize(pdf_path)
    @pdf_path = pdf_path
    validate_file!
  end

  def extract_chapters
    reader = PDF::Reader.new(@pdf_path)

    # Access the catalog through the trailer
    catalog = reader.objects.trailer[:Root]
    return 'No outline/chapters found in this PDF.' unless catalog

    catalog_obj = reader.objects[catalog]
    return 'No outline/chapters found in this PDF.' unless catalog_obj && catalog_obj[:Outlines]

    outline_root = reader.objects[catalog_obj[:Outlines]]
    return 'No outline/chapters found in this PDF.' unless outline_root && outline_root[:First]

    chapters = []
    parse_outline_item(reader, outline_root[:First], chapters, 0)

    chapters.empty? ? 'No outline/chapters found in this PDF.' : chapters
  rescue PDF::Reader::MalformedPDFError => e
    raise "Error reading PDF: #{e.message}"
  rescue StandardError => e
    raise "Unexpected error: #{e.message}"
  end

  def to_markdown
    chapters = extract_chapters

    output = ["# #{File.basename(@pdf_path)}", '']

    if chapters.is_a?(String)
      output << chapters
    else
      render_chapters(chapters, output)
    end

    output.join("\n")
  end

  private

  def validate_file!
    raise "File not found: #{@pdf_path}" unless File.exist?(@pdf_path)
    raise "Not a PDF file: #{@pdf_path}" unless File.extname(@pdf_path).downcase == '.pdf'
  end

  def parse_outline_item(reader, item_ref, chapters, level)
    return unless item_ref

    item = reader.objects[item_ref]
    return unless item

    # Extract title
    title = decode_pdf_string(item[:Title])

    # Extract page number
    page_num = extract_page_number(reader, item)

    if title
      chapters << {
        title: title,
        page: page_num,
        level: level
      }
    end

    # Process children
    parse_outline_item(reader, item[:First], chapters, level + 1) if item[:First]

    # Process siblings
    return unless item[:Next]

    parse_outline_item(reader, item[:Next], chapters, level)
  end

  def decode_pdf_string(str)
    return nil unless str&.is_a?(String)

    # Try UTF-16BE first (common in PDFs)
    if str.bytes.first(2) == [254, 255] || str.include?("\x00")
      begin
        str = str.force_encoding('UTF-16BE').encode('UTF-8')
      rescue StandardError
        # Fall back to forcing UTF-8
        str = str.force_encoding('UTF-8')
        str = str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') unless str.valid_encoding?
      end
    else
      str = str.force_encoding('UTF-8')
      str = str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') unless str.valid_encoding?
    end

    # Remove BOM and other invisible characters
    str = str.delete_prefix("\uFEFF") # Remove BOM
    str.strip # Remove leading/trailing whitespace
  end

  def extract_page_number(reader, item)
    dest = item[:Dest] || (item[:A] && item[:A][:D])
    return nil unless dest

    # If dest is a reference, resolve it
    dest = reader.objects[dest] if dest.is_a?(PDF::Reader::Reference)

    if dest.is_a?(Array) && !dest.empty?
      page_ref = dest.first

      # Find the page number
      reader.pages.each_with_index do |page, index|
        if page_ref.is_a?(PDF::Reader::Reference) && (page.page_object.hash == reader.objects[page_ref].hash)
          return index + 1
        end
      end
    end

    nil
  rescue StandardError
    nil
  end

  def render_chapters(chapters, output, _indent = '')
    chapters.each do |chapter|
      level_indent = '  ' * chapter[:level]
      page_info = chapter[:page] ? " (p.#{chapter[:page]})" : ''
      output << "#{level_indent}- #{chapter[:title]}#{page_info}"
    end
  end
end

def print_usage
  puts <<~USAGE
    Usage: bundle exec ruby pdf_chapter_tree.rb <path/to/pdf_file>

    This script extracts and displays the chapter structure of a PDF file
    in a hierarchical Markdown format.

    Example:
      bundle exec ruby pdf_chapter_tree.rb document.pdf

    Requirements:
      - Ruby 3.4 or higher
      - pdf-reader gem (install with: bundle install)
  USAGE
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty? || ARGV[0] == '-h' || ARGV[0] == '--help'
    print_usage
    exit 0
  end

  begin
    pdf_path = ARGV[0]
    extractor = PDFChapterTree.new(pdf_path)
    puts extractor.to_markdown
  rescue StandardError => e
    puts "Error: #{e.message}"
    puts
    print_usage
    exit 1
  end
end
