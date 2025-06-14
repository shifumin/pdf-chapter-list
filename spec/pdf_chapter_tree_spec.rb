# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PDFChapterTree do
  let(:valid_pdf_path) { 'spec/fixtures/sample_with_outline.pdf' }
  let(:pdf_without_outline_path) { 'spec/fixtures/sample_without_outline.pdf' }
  let(:japanese_pdf_path) { 'spec/fixtures/japanese_with_outline.pdf' }
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
        expect(markdown).to include('- 1. Introduction')
        expect(markdown).to include('  - 1.1 Background')
        expect(markdown).to include('  - 1.2 Overview')
        expect(markdown).to include('- 2. Getting Started')
        expect(markdown).to include('- 3. Advanced Topics')
      end

      context 'with depth limit' do
        it 'shows only specified levels when depth is 1' do
          extractor = described_class.new(valid_pdf_path)
          markdown = extractor.to_markdown(max_depth: 1)

          expect(markdown).to include('# sample_with_outline.pdf')
          expect(markdown).to include('- 1. Introduction')
          expect(markdown).to include('- 2. Getting Started')
          expect(markdown).to include('- 3. Advanced Topics')
          # Should not include level 2 items
          expect(markdown).not_to include('  - 1.1 Background')
          expect(markdown).not_to include('  - 1.2 Overview')
        end

        it 'shows two levels when depth is 2' do
          extractor = described_class.new(valid_pdf_path)
          markdown = extractor.to_markdown(max_depth: 2)

          expect(markdown).to include('# sample_with_outline.pdf')
          expect(markdown).to include('- 1. Introduction')
          expect(markdown).to include('  - 1.1 Background')
          expect(markdown).to include('  - 1.2 Overview')
          expect(markdown).to include('- 2. Getting Started')
          # If there were level 3 items, they should not be included
        end

        it 'shows all levels when depth exceeds available levels' do
          extractor = described_class.new(valid_pdf_path)
          markdown = extractor.to_markdown(max_depth: 10)

          # Should show all available levels (same as no limit)
          expect(markdown).to include('# sample_with_outline.pdf')
          expect(markdown).to include('- 1. Introduction')
          expect(markdown).to include('  - 1.1 Background')
          expect(markdown).to include('  - 1.2 Overview')
          expect(markdown).to include('- 2. Getting Started')
        end
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

    context 'with Japanese PDF containing UTF-16BE encoded outline' do
      it 'correctly decodes and displays Japanese titles' do
        extractor = described_class.new(japanese_pdf_path)
        markdown = extractor.to_markdown

        expect(markdown).to include('# japanese_with_outline.pdf')
        expect(markdown).to include('- 表紙')
        expect(markdown).to include('- 目次')
        expect(markdown).to include('- 第Ⅰ部 基礎知識')
        expect(markdown).to include('  - 1章 はじめに')
        expect(markdown).to include('    - 1.1 背景と目的')
        expect(markdown).to include('    - 1.2 本書の構成')
        expect(markdown).to include('  - 2章 環境構築')
        expect(markdown).to include('    - 2.1 必要なツール')
        expect(markdown).to include('- 第Ⅱ部 実践編')
        expect(markdown).to include('  - 3章 基本的な使い方')
      end

      context 'with depth limit' do
        it 'shows only top level when depth is 1' do
          extractor = described_class.new(japanese_pdf_path)
          markdown = extractor.to_markdown(max_depth: 1)

          expect(markdown).to include('- 表紙')
          expect(markdown).to include('- 目次')
          expect(markdown).to include('- 第Ⅰ部 基礎知識')
          expect(markdown).to include('- 第Ⅱ部 実践編')
          # Should not include level 2 or deeper
          expect(markdown).not_to include('  - 1章 はじめに')
          expect(markdown).not_to include('    - 1.1 背景と目的')
        end

        it 'shows up to level 2 when depth is 2' do
          extractor = described_class.new(japanese_pdf_path)
          markdown = extractor.to_markdown(max_depth: 2)

          expect(markdown).to include('- 表紙')
          expect(markdown).to include('- 第Ⅰ部 基礎知識')
          expect(markdown).to include('  - 1章 はじめに')
          expect(markdown).to include('  - 2章 環境構築')
          # Should not include level 3
          expect(markdown).not_to include('    - 1.1 背景と目的')
          expect(markdown).not_to include('    - 2.1 必要なツール')
        end
      end
    end
  end

  describe '#extract_page_number' do
    let(:extractor) { described_class.new(valid_pdf_path) }
    let(:reader) { double('PDF::Reader') }

    before do
      allow(PDF::Reader).to receive(:new).and_return(reader)
      allow(reader).to receive(:objects).and_return(double('objects'))
      allow(reader).to receive(:pages).and_return([])
    end

    context 'with named destination (string format like "p35")' do
      it 'extracts page number from string pattern' do
        item = { A: { D: 'p35' } }

        # Access private method for testing
        page_num = extractor.send(:extract_page_number, reader, item)

        expect(page_num).to eq(35)
      end

      it 'handles various page number formats' do
        test_cases = {
          'p1' => 1,
          'p99' => 99,
          'p123' => 123,
          'page1' => nil,  # Different format, not handled
          'p' => nil,      # No number
          '' => nil        # Empty string
        }

        test_cases.each do |dest_string, expected|
          item = { A: { D: dest_string } }
          page_num = extractor.send(:extract_page_number, reader, item)
          expect(page_num).to eq(expected), "Expected '#{dest_string}' to return #{expected.inspect}"
        end
      end
    end

    context 'with Action containing string destination' do
      it 'resolves Action reference and extracts page from string' do
        action_ref = double('PDF::Reader::Reference')
        action_obj = { D: 'p42', S: :GoTo }
        item = { A: action_ref }

        allow(action_ref).to receive(:is_a?).with(PDF::Reader::Reference).and_return(true)
        allow(reader.objects).to receive(:[]).with(action_ref).and_return(action_obj)

        page_num = extractor.send(:extract_page_number, reader, item)

        expect(page_num).to eq(42)
      end
    end
  end

  describe '#to_tree' do
    context 'with PDF containing chapters' do
      it 'generates tree format output' do
        extractor = described_class.new(valid_pdf_path)
        tree = extractor.to_tree

        expect(tree).to include('sample_with_outline.pdf')
        expect(tree).to include('├── 1. Introduction')
        expect(tree).to include('│   ├── 1.1 Background')
        expect(tree).to include('│   └── 1.2 Overview')
        expect(tree).to include('├── 2. Getting Started')
        expect(tree).to include('└── 3. Advanced Topics')
      end

      context 'with depth limit' do
        it 'shows only specified levels when depth is 1' do
          extractor = described_class.new(valid_pdf_path)
          tree = extractor.to_tree(max_depth: 1)

          expect(tree).to include('sample_with_outline.pdf')
          expect(tree).to include('├── 1. Introduction')
          expect(tree).to include('├── 2. Getting Started')
          expect(tree).to include('└── 3. Advanced Topics')
          # Should not include level 2 items
          expect(tree).not_to include('│   ├── 1.1 Background')
          expect(tree).not_to include('│   └── 1.2 Overview')
        end

        it 'shows two levels when depth is 2' do
          extractor = described_class.new(valid_pdf_path)
          tree = extractor.to_tree(max_depth: 2)

          expect(tree).to include('sample_with_outline.pdf')
          expect(tree).to include('├── 1. Introduction')
          expect(tree).to include('│   ├── 1.1 Background')
          expect(tree).to include('│   └── 1.2 Overview')
          expect(tree).to include('├── 2. Getting Started')
          expect(tree).to include('└── 3. Advanced Topics')
        end
      end
    end

    context 'with PDF without outline' do
      it 'returns appropriate message' do
        extractor = described_class.new(pdf_without_outline_path)
        tree = extractor.to_tree

        expect(tree).to include('sample_without_outline.pdf')
        expect(tree).to include('No outline/chapters found in this PDF.')
      end
    end

    context 'with Japanese PDF containing UTF-16BE encoded outline' do
      it 'correctly displays Japanese titles in tree format' do
        extractor = described_class.new(japanese_pdf_path)
        tree = extractor.to_tree

        expect(tree).to include('japanese_with_outline.pdf')
        expect(tree).to include('├── 表紙')
        expect(tree).to include('├── 目次')
        expect(tree).to include('├── 第Ⅰ部 基礎知識')
        expect(tree).to include('│   ├── 1章 はじめに')
        expect(tree).to include('│   │   ├── 1.1 背景と目的')
        expect(tree).to include('│   │   └── 1.2 本書の構成')
        expect(tree).to include('│   └── 2章 環境構築')
        expect(tree).to include('│       └── 2.1 必要なツール')
        expect(tree).to include('└── 第Ⅱ部 実践編')
        expect(tree).to include('    └── 3章 基本的な使い方')
      end

      context 'with depth limit' do
        it 'shows only top level when depth is 1' do
          extractor = described_class.new(japanese_pdf_path)
          tree = extractor.to_tree(max_depth: 1)

          expect(tree).to include('├── 表紙')
          expect(tree).to include('├── 目次')
          expect(tree).to include('├── 第Ⅰ部 基礎知識')
          expect(tree).to include('└── 第Ⅱ部 実践編')
          # Should not include level 2 or deeper
          expect(tree).not_to include('│   ├── 1章 はじめに')
          expect(tree).not_to include('│   │   ├── 1.1 背景と目的')
        end

        it 'shows up to level 2 when depth is 2' do
          extractor = described_class.new(japanese_pdf_path)
          tree = extractor.to_tree(max_depth: 2)

          expect(tree).to include('├── 表紙')
          expect(tree).to include('├── 第Ⅰ部 基礎知識')
          expect(tree).to include('│   ├── 1章 はじめに')
          expect(tree).to include('│   └── 2章 環境構築')
          # Should not include level 3
          expect(tree).not_to include('│   │   ├── 1.1 背景と目的')
          expect(tree).not_to include('│   │   └── 2.1 必要なツール')
        end
      end
    end
  end
end
