#!/usr/bin/env ruby
# frozen_string_literal: true

require "pdf-reader"
require "optparse"

class PDFChapterTree
  def initialize(pdf_path)
    @pdf_path = pdf_path
    validate_file!
  end

  def extract_chapters
    reader = PDF::Reader.new(@pdf_path)
    outline_root = find_outline_root(reader)

    return "No outline/chapters found in this PDF." unless outline_root

    chapters = []
    parse_outline_item(reader, outline_root[:First], chapters, 0)

    chapters.empty? ? "No outline/chapters found in this PDF." : chapters
  rescue PDF::Reader::MalformedPDFError => e
    raise "Error reading PDF: #{e.message}"
  rescue StandardError => e
    raise "Unexpected error: #{e.message}"
  end

  def find_outline_root(reader)
    catalog = reader.objects.trailer[:Root]
    return nil unless catalog

    catalog_obj = reader.objects[catalog]
    return nil unless catalog_obj && catalog_obj[:Outlines]

    outline_root = reader.objects[catalog_obj[:Outlines]]
    return nil unless outline_root && outline_root[:First]

    outline_root
  end

  def to_markdown(max_depth: nil, indent: 2)
    chapters = extract_chapters

    output = ["# #{File.basename(@pdf_path)}", ""]

    if chapters.is_a?(String)
      output << chapters
    else
      render_chapters(chapters, output, max_depth: max_depth, indent: indent)
    end

    output.join("\n")
  end

  def to_tree(max_depth: nil, indent: 2)
    chapters = extract_chapters

    output = [File.basename(@pdf_path)]

    if chapters.is_a?(String)
      output << chapters
    else
      render_tree(chapters, output, max_depth: max_depth, indent: indent)
    end

    output.join("\n")
  end

  private

  def validate_file!
    raise "File not found: #{@pdf_path}" unless File.exist?(@pdf_path)
    raise "Not a PDF file: #{@pdf_path}" unless File.extname(@pdf_path).downcase == ".pdf"
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
    return nil unless str.is_a?(String)

    # Try UTF-16BE first (common in PDFs)
    if str.bytes.first(2) == [254, 255] || str.include?("\x00")
      begin
        str = str.force_encoding("UTF-16BE").encode("UTF-8")
      rescue StandardError
        # Fall back to forcing UTF-8
        str = str.force_encoding("UTF-8")
        str = str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?") unless str.valid_encoding?
      end
    else
      str = str.force_encoding("UTF-8")
      str = str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?") unless str.valid_encoding?
    end

    # Remove BOM and other invisible characters
    str = str.delete_prefix("\uFEFF") # Remove BOM

    # Replace full-width space with half-width space
    str = str.tr("　", " ")

    str.strip # Remove leading/trailing whitespace
  end

  def extract_page_number(reader, item)
    dest = get_destination(reader, item)
    return nil unless dest

    # If dest is a reference, resolve it
    dest = reader.objects[dest] if dest.is_a?(PDF::Reader::Reference)

    case dest
    when Array
      extract_page_from_array_dest(reader, dest)
    when String
      extract_page_from_string_dest(dest)
    end
  rescue StandardError
    nil
  end

  def get_destination(reader, item)
    # Try direct Dest first
    return item[:Dest] if item[:Dest]

    # If no direct Dest, check for Action
    return nil unless item[:A]

    action = item[:A]
    # Resolve Action reference if needed
    action = reader.objects[action] if action.is_a?(PDF::Reader::Reference)
    # Get Dest from Action
    action.is_a?(Hash) ? action[:D] : nil
  end

  def extract_page_from_array_dest(reader, dest)
    return nil if dest.empty?

    page_ref = dest.first

    # Find the page number
    reader.pages.each_with_index do |page, index|
      if page_ref.is_a?(PDF::Reader::Reference) && (page.page_object.hash == reader.objects[page_ref].hash)
        return index + 1
      end
    end

    nil
  end

  def extract_page_from_string_dest(dest)
    # Handle named destinations (e.g., "p35")
    # For simple page number patterns, extract directly
    return ::Regexp.last_match(1).to_i if dest =~ /^p(\d+)$/

    # For complex named destinations, would need to resolve through Names dictionary
    # This is not implemented yet as it requires complex PDF structure parsing
    nil
  end

  def render_chapters(chapters, output, max_depth: nil, indent: 2)
    chapters.each do |chapter|
      # Skip chapters beyond max_depth if specified
      next if max_depth && (chapter[:level] + 1) > max_depth

      level_indent = " " * (indent * chapter[:level])
      page_info = chapter[:page] ? " (p.#{chapter[:page]})" : ""
      output << "#{level_indent}- #{chapter[:title]}#{page_info}"
    end
  end

  def render_tree(chapters, output, max_depth: nil, indent: 2)
    visible_chapters = filter_chapters_by_depth(chapters, max_depth)

    visible_chapters.each_with_index do |chapter, index|
      is_last_at_level = last_at_level?(visible_chapters, index)
      tree_prefix = build_tree_prefix(visible_chapters, index, chapter[:level], indent)
      render_tree_line(output, chapter, tree_prefix, is_last_at_level)
    end
  end

  def filter_chapters_by_depth(chapters, max_depth)
    return chapters unless max_depth

    chapters.select { |ch| (ch[:level] + 1) <= max_depth }
  end

  def last_at_level?(chapters, index)
    current_level = chapters[index][:level]

    ((index + 1)...chapters.length).each do |j|
      next_level = chapters[j][:level]
      return false if next_level == current_level
      break if next_level < current_level
    end

    true
  end

  def build_tree_prefix(chapters, index, current_level, indent = 2)
    prefix = ""

    (0...current_level).each do |parent_level|
      has_more = more_at_parent_level?(chapters, index, parent_level)
      prefix += has_more ? "│#{' ' * (indent + 1)}" : " " * (indent + 2)
    end

    prefix
  end

  def more_at_parent_level?(chapters, index, parent_level)
    ((index + 1)...chapters.length).each do |j|
      level = chapters[j][:level]
      return true if level == parent_level
      return false if level < parent_level
    end

    false
  end

  def render_tree_line(output, chapter, tree_prefix, is_last)
    branch = is_last ? "└── " : "├── "
    page_info = chapter[:page] ? " (p.#{chapter[:page]})" : ""
    output << "#{tree_prefix}#{branch}#{chapter[:title]}#{page_info}"
  end
end

def parse_options
  options = {}

  parser = create_option_parser(options)
  parser.parse!
  options
rescue OptionParser::InvalidOption => e
  puts "Error: #{e.message}"
  puts
  puts parser.help
  exit 1
end

def create_option_parser(options)
  OptionParser.new do |opts|
    opts.banner = "Usage: bundle exec ruby pdf_chapter_tree.rb [options] <path/to/pdf_file>"

    opts.on("-d", "--depth LEVEL", Integer, "Display only LEVEL levels of hierarchy") do |level|
      if level <= 0
        puts "Error: Depth must be a positive integer"
        exit 1
      end
      options[:depth] = level
    end

    opts.on("-t", "--tree", "Display output in tree format instead of Markdown list") do
      options[:tree] = true
    end

    opts.on("-i", "--indent SPACES", Integer, "Set indent spacing (default: 2)") do |spaces|
      if spaces <= 0
        puts "Error: Indent must be a positive integer"
        exit 1
      end
      options[:indent] = spaces
    end

    opts.on("-h", "--help", "Show this help message") do
      show_help(opts)
      exit
    end
  end
end

def show_help(opts)
  puts opts
  puts
  puts "Description:"
  puts "  This script extracts and displays the chapter structure of a PDF file"
  puts "  in a hierarchical format (Markdown list by default, or tree format with -t)."
  puts
  puts "Examples:"
  puts "  bundle exec ruby pdf_chapter_tree.rb document.pdf               # Show all levels in Markdown"
  puts "  bundle exec ruby pdf_chapter_tree.rb -t document.pdf            # Show all levels in tree format"
  puts "  bundle exec ruby pdf_chapter_tree.rb -d 2 document.pdf          # Show only 2 levels in Markdown"
  puts "  bundle exec ruby pdf_chapter_tree.rb -t -d 2 document.pdf       # Show only 2 levels in tree format"
  puts "  bundle exec ruby pdf_chapter_tree.rb -i 4 document.pdf          # Use 4-space indent (for Obsidian)"
  puts "  bundle exec ruby pdf_chapter_tree.rb -i 4 -d 2 document.pdf     # Combine 4-space indent with depth limit"
  puts "  bundle exec ruby pdf_chapter_tree.rb --tree document.pdf        # Show all levels in tree format"
  puts
  puts "Requirements:"
  puts "  - Ruby 3.4 or higher"
  puts "  - pdf-reader gem (install with: bundle install)"
end

if __FILE__ == $PROGRAM_NAME
  options = parse_options

  if ARGV.empty?
    puts "Error: No PDF file specified"
    puts
    puts "Usage: bundle exec ruby pdf_chapter_tree.rb [options] <path/to/pdf_file>"
    puts "Try 'bundle exec ruby pdf_chapter_tree.rb --help' for more information."
    exit 1
  end

  begin
    pdf_path = ARGV[0]
    extractor = PDFChapterTree.new(pdf_path)

    if options[:tree]
      puts extractor.to_tree(max_depth: options[:depth], indent: options[:indent] || 2)
    else
      puts extractor.to_markdown(max_depth: options[:depth], indent: options[:indent] || 2)
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    exit 1
  end
end
