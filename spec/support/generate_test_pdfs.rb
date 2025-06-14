#!/usr/bin/env ruby
# frozen_string_literal: true

require 'prawn'
require 'fileutils'

FileUtils.mkdir_p('spec/fixtures')

# Generate PDF with outline
Prawn::Document.generate('spec/fixtures/sample_with_outline.pdf') do |pdf|
  pdf.text 'Sample PDF with Outline', size: 24, style: :bold
  pdf.move_down 20

  # Chapter 1
  pdf.start_new_page
  pdf.text '1. Introduction', size: 20, style: :bold
  pdf.move_down 10
  pdf.text 'This is the introduction chapter.'

  # Chapter 1.1
  pdf.start_new_page
  pdf.text '1.1 Background', size: 18, style: :bold
  pdf.move_down 10
  pdf.text 'This section covers the background information.'

  # Chapter 1.2
  pdf.start_new_page
  pdf.text '1.2 Overview', size: 18, style: :bold
  pdf.move_down 10
  pdf.text 'This section provides an overview.'

  # Chapter 2
  pdf.start_new_page
  pdf.text '2. Getting Started', size: 20, style: :bold
  pdf.move_down 10
  pdf.text 'This chapter helps you get started.'

  # Chapter 2.1
  pdf.start_new_page
  pdf.text '2.1 Installation', size: 18, style: :bold
  pdf.move_down 10
  pdf.text 'Installation instructions go here.'

  # Chapter 2.2
  pdf.start_new_page
  pdf.text '2.2 Configuration', size: 18, style: :bold
  pdf.move_down 10
  pdf.text 'Configuration details are explained here.'

  # Chapter 3
  pdf.start_new_page
  pdf.text '3. Advanced Topics', size: 20, style: :bold
  pdf.move_down 10
  pdf.text 'This chapter covers advanced topics.'

  # Create outline
  pdf.outline.define do
    section('1. Introduction', destination: 2) do
      page(title: '1.1 Background', destination: 3)
      page(title: '1.2 Overview', destination: 4)
    end
    section('2. Getting Started', destination: 5) do
      page(title: '2.1 Installation', destination: 6)
      page(title: '2.2 Configuration', destination: 7)
    end
    section('3. Advanced Topics', destination: 8)
  end
end

# Generate PDF without outline
Prawn::Document.generate('spec/fixtures/sample_without_outline.pdf') do |pdf|
  pdf.text 'Sample PDF without Outline', size: 24, style: :bold
  pdf.move_down 20
  pdf.text 'This PDF has content but no outline/bookmarks.'

  pdf.start_new_page
  pdf.text 'Page 2', size: 20, style: :bold
  pdf.move_down 10
  pdf.text 'This is the second page.'

  pdf.start_new_page
  pdf.text 'Page 3', size: 20, style: :bold
  pdf.move_down 10
  pdf.text 'This is the third page.'
end

# Generate Japanese PDF with outline
# Note: For cross-platform compatibility, we'll use ASCII characters in the PDF content
# but UTF-16BE encoded titles in the outline to simulate real Japanese PDFs
Prawn::Document.generate('spec/fixtures/japanese_with_outline.pdf') do |pdf|
  pdf.text 'Japanese Technical Book Sample', size: 24, style: :bold
  pdf.move_down 20

  # Cover page
  pdf.start_new_page
  pdf.text 'Cover', size: 20, style: :bold

  # Table of contents
  pdf.start_new_page
  pdf.text 'Table of Contents', size: 20, style: :bold

  # Part 1
  pdf.start_new_page
  pdf.text 'Part I - Basic Knowledge', size: 20, style: :bold

  # Chapter 1
  pdf.start_new_page
  pdf.text 'Chapter 1 - Introduction', size: 18, style: :bold

  # Section 1.1
  pdf.start_new_page
  pdf.text '1.1 Background and Purpose', size: 16

  # Section 1.2
  pdf.start_new_page
  pdf.text '1.2 Book Structure', size: 16

  # Chapter 2
  pdf.start_new_page
  pdf.text 'Chapter 2 - Environment Setup', size: 18, style: :bold

  # Section 2.1
  pdf.start_new_page
  pdf.text '2.1 Required Tools', size: 16

  # Part 2
  pdf.start_new_page
  pdf.text 'Part II - Practical Guide', size: 20, style: :bold

  # Chapter 3
  pdf.start_new_page
  pdf.text 'Chapter 3 - Basic Usage', size: 18, style: :bold

  # Create outline with UTF-16BE encoded titles (simulating real Japanese PDFs)
  pdf.outline.define do
    page(title: '表紙'.encode('UTF-16BE'), destination: 2)
    page(title: '目次'.encode('UTF-16BE'), destination: 3)
    section('第Ⅰ部 基礎知識'.encode('UTF-16BE'), destination: 4) do
      section('1章 はじめに'.encode('UTF-16BE'), destination: 5) do
        page(title: '1.1 背景と目的'.encode('UTF-16BE'), destination: 6)
        page(title: '1.2 本書の構成'.encode('UTF-16BE'), destination: 7)
      end
      section('2章 環境構築'.encode('UTF-16BE'), destination: 8) do
        page(title: '2.1 必要なツール'.encode('UTF-16BE'), destination: 9)
      end
    end
    section('第Ⅱ部 実践編'.encode('UTF-16BE'), destination: 10) do
      page(title: '3章 基本的な使い方'.encode('UTF-16BE'), destination: 11)
    end
  end
end

# Generate PDF with named destinations (like O'Reilly books)
# Note: Prawn doesn't directly support named destinations in outline,
# so we'll simulate the structure by creating a PDF that our code will handle
Prawn::Document.generate('spec/fixtures/named_dest_outline.pdf') do |pdf|
  pdf.text 'Technical Book with Named Destinations', size: 24, style: :bold
  pdf.move_down 20

  # Preface
  pdf.start_new_page
  pdf.text 'Preface', size: 20, style: :bold

  # Table of Contents
  pdf.start_new_page
  pdf.text 'Table of Contents', size: 20, style: :bold

  # Part 1
  pdf.start_new_page
  pdf.text 'Part I - Fundamentals', size: 20, style: :bold

  # Chapter 1
  pdf.start_new_page
  pdf.text 'Chapter 1 - Introduction', size: 18, style: :bold

  # Section 1.1
  pdf.start_new_page
  pdf.text '1.1 Getting Started', size: 16

  # Section 1.2
  pdf.start_new_page
  pdf.text '1.2 Basic Concepts', size: 16

  # Chapter 2
  pdf.start_new_page
  pdf.text 'Chapter 2 - Advanced Topics', size: 18, style: :bold

  # Section 2.1
  pdf.start_new_page
  pdf.text '2.1 Deep Dive', size: 16

  # Part 2
  pdf.start_new_page
  pdf.text 'Part II - Practice', size: 20, style: :bold

  # Chapter 3
  pdf.start_new_page
  pdf.text 'Chapter 3 - Real World Examples', size: 18, style: :bold

  # Create outline
  # Since Prawn doesn't support creating PDFs with string destinations directly,
  # we'll create a normal outline and our test will mock the string destination behavior
  pdf.outline.define do
    page(title: 'Preface', destination: 2)
    page(title: 'Table of Contents', destination: 3)
    section('Part I - Fundamentals', destination: 4) do
      section('Chapter 1 - Introduction', destination: 5) do
        page(title: '1.1 Getting Started', destination: 6)
        page(title: '1.2 Basic Concepts', destination: 7)
      end
      section('Chapter 2 - Advanced Topics', destination: 8) do
        page(title: '2.1 Deep Dive', destination: 9)
      end
    end
    section('Part II - Practice', destination: 10) do
      page(title: 'Chapter 3 - Real World Examples', destination: 11)
    end
  end
end

puts 'Test PDFs generated successfully in spec/fixtures/'
puts '- sample_with_outline.pdf'
puts '- sample_without_outline.pdf'
puts '- japanese_with_outline.pdf'
puts '- named_dest_outline.pdf'
