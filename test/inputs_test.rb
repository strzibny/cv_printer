require 'test_helper'

class InputsTest < Minitest::Test
  include CvPrinterHelpers

  def test_refuse_documents_of_wrong_class
    assert_raises(StandardError) do
      CvPrinter::PDFDocument.new(document: String.new)
    end

    assert_raises(StandardError) do
      CvPrinter.render(document: String.new)
    end
  end

  def test_refuse_items_of_wrong_class
    assert_raises(StandardError) do
      CvPrinter::Document.new(items: String.new)
    end
  end

  def test_non_string_inputs_are_converted_to_strings
    params = default_document_params.merge(
      provider_tax_id: 12345678910,
      provider_tax_id2: 12345678910,
      purchaser_tax_id: 12345678910,
      purchaser_tax_id2: 12345678910
    )

    # No exceptions should be raised
    invoice = CvPrinter::Document.new(**params)
    CvPrinter.render(document: invoice)
  end

  def test_missing_font_raises_an_exception
    invoice = CvPrinter::Document.new(**default_document_params)

    assert_raises(CvPrinter::PDFDocument::FontFileNotFound) do
      CvPrinter.render(document: invoice, font: 'missing.font')
    end
  end

  def test_missing_logo_raises_an_exception
    invoice = CvPrinter::Document.new(**default_document_params)

    assert_raises(CvPrinter::PDFDocument::LogoFileNotFound) do
      CvPrinter.render(document: invoice, logo: 'missing.png')
    end
  end

  def test_missing_stamp_raises_an_exception
    invoice = CvPrinter::Document.new(**default_document_params)

    assert_raises(CvPrinter::PDFDocument::StampFileNotFound) do
      CvPrinter.render(document: invoice, stamp: 'missing.png')
    end
  end

  def test_missing_qr_raises_an_exception
    invoice = CvPrinter::Document.new(**default_document_params)

    assert_raises(CvPrinter::PDFDocument::QRFileNotFound) do
      CvPrinter.render(document: invoice, qr: 'missing.png')
    end
  end
end
