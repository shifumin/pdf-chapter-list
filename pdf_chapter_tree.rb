#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pdf-reader'
require 'optparse'

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

  def to_markdown(max_depth: nil)
    chapters = extract_chapters

    output = ["# #{File.basename(@pdf_path)}", '']

    if chapters.is_a?(String)
      output << chapters
    else
      render_chapters(chapters, output, max_depth: max_depth)
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
    return nil unless str.is_a?(String)

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

    # Replace full-width space with half-width space
    str = str.tr('　', ' ')

    str.strip # Remove leading/trailing whitespace
  end

  def extract_page_number(reader, item)
    # Try direct Dest first
    dest = item[:Dest]

    # If no direct Dest, check for Action
    if !dest && item[:A]
      action = item[:A]
      # Resolve Action reference if needed
      action = reader.objects[action] if action.is_a?(PDF::Reader::Reference)
      # Get Dest from Action
      dest = action[:D] if action.is_a?(Hash)
    end

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
    elsif dest.is_a?(String)
      # Handle named destinations (e.g., "p35")
      # For simple page number patterns, extract directly
      return ::Regexp.last_match(1).to_i if dest =~ /^p(\d+)$/

      # For complex named destinations, would need to resolve through Names dictionary
      # This is not implemented yet as it requires complex PDF structure parsing
    end

    nil
  rescue StandardError
    nil
  end

  def render_chapters(chapters, output, max_depth: nil)
    chapters.each do |chapter|
      # Skip chapters beyond max_depth if specified
      next if max_depth && (chapter[:level] + 1) > max_depth

      level_indent = '  ' * chapter[:level]
      page_info = chapter[:page] ? " (p.#{chapter[:page]})" : ''
      output << "#{level_indent}- #{chapter[:title]}#{page_info}"
    end
  end
end

def parse_options
  options = {}

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: bundle exec ruby pdf_chapter_tree.rb [options] <path/to/pdf_file>'

    opts.on('-d', '--depth LEVEL', Integer, 'Display only LEVEL levels of hierarchy') do |level|
      if level <= 0
        puts 'Error: Depth must be a positive integer'
        exit 1
      end
      options[:depth] = level
    end

    opts.on('-h', '--help', 'Show this help message') do
      puts opts
      puts
      puts 'Description:'
      puts '  This script extracts and displays the chapter structure of a PDF file'
      puts '  in a hierarchical Markdown format.'
      puts
      puts 'Examples:'
      puts '  bundle exec ruby pdf_chapter_tree.rb document.pdf               # Show all levels'
      puts '  bundle exec ruby pdf_chapter_tree.rb -d 2 document.pdf          # Show only 2 levels'
      puts '  bundle exec ruby pdf_chapter_tree.rb --depth 1 document.pdf     # Show only top level'
      puts
      puts 'Requirements:'
      puts '  - Ruby 3.4 or higher'
      puts '  - pdf-reader gem (install with: bundle install)'
      exit
    end
  end

  parser.parse!
  options
rescue OptionParser::InvalidOption => e
  puts "Error: #{e.message}"
  puts
  puts parser.help
  exit 1
end

if __FILE__ == $PROGRAM_NAME
  options = parse_options

  if ARGV.empty?
    puts 'Error: No PDF file specified'
    puts
    puts 'Usage: bundle exec ruby pdf_chapter_tree.rb [options] <path/to/pdf_file>'
    puts "Try 'bundle exec ruby pdf_chapter_tree.rb --help' for more information."
    exit 1
  end

  begin
    pdf_path = ARGV[0]
    extractor = PDFChapterTree.new(pdf_path)
    puts extractor.to_markdown(max_depth: options[:depth])
  rescue StandardError => e
    puts "Error: #{e.message}"
    exit 1
  end
end
