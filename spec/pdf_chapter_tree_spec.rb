# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDFChapterTree do
  let(:valid_pdf_path) { 'spec/fixtures/sample_with_outline.pdf' }
  let(:pdf_without_outline_path) { 'spec/fixtures/sample_without_outline.pdf' }
  let(:non_existent_path) { 'spec/fixtures/non_existent.pdf' }
  let(:non_pdf_path) { 'spec/fixtures/sample.txt' }

  describe '#initialize' do
    context 'with valid PDF file' do
      it 'creates an instance without errors' do
        expect { described_class.new(valid_pdf_path) }.not_to raise_error
      end
    end

    context 'with non-existent file' do
      it 'raises an error' do
        expect { described_class.new(non_existent_path) }
          .to raise_error(RuntimeError, /File not found/)
      end
    end

    context 'with non-PDF file' do
      before do
        File.write(non_pdf_path, 'This is not a PDF')
      end

      after do
        FileUtils.rm_f(non_pdf_path)
      end

      it 'raises an error' do
        expect { described_class.new(non_pdf_path) }
          .to raise_error(RuntimeError, /Not a PDF file/)
      end
    end
  end

  describe '#extract_chapters' do
    context 'with PDF containing outline' do
      it 'extracts chapter information' do
        extractor = described_class.new(valid_pdf_path)
        chapters = extractor.extract_chapters

        expect(chapters).to be_an(Array)
        expect(chapters).not_to be_empty
        expect(chapters.first[:title]).to eq('1. Introduction')
        expect(chapters.first[:level]).to eq(0)
      end
    end

    context 'with PDF without outline' do
      it 'returns a message indicating no outline found' do
        extractor = described_class.new(pdf_without_outline_path)
        result = extractor.extract_chapters

        expect(result).to eq('No outline/chapters found in this PDF.')
      end
    end
  end

  describe '#to_markdown' do
    context 'with PDF containing chapters' do
      it 'generates markdown format output' do
        extractor = described_class.new(valid_pdf_path)
        markdown = extractor.to_markdown

        expect(markdown).to include('# sample_with_outline.pdf')
        expect(markdown).to include('- **1. Introduction**')
        expect(markdown).to include('  - **1.1 Background**')
        expect(markdown).to include('  - **1.2 Overview**')
        expect(markdown).to include('- **2. Getting Started**')
        expect(markdown).to include('- **3. Advanced Topics**')
      end
    end

    context 'with PDF without outline' do
      it 'returns appropriate message' do
        extractor = described_class.new(pdf_without_outline_path)
        markdown = extractor.to_markdown

        expect(markdown).to include('# sample_without_outline.pdf')
        expect(markdown).to include('No outline/chapters found in this PDF.')
      end
    end
  end
end
