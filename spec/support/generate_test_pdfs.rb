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

puts 'Test PDFs generated successfully in spec/fixtures/'
puts '- sample_with_outline.pdf'
puts '- sample_without_outline.pdf'
