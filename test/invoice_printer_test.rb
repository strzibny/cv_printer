require 'test_helper'

class CvPrinterTest < Minitest::Test
  include CvPrinterHelpers

  def test_render_document
    invoice      = CvPrinter::Document.new(**default_document_params)
    rendered_pdf = CvPrinter.render(document: invoice)
    pdf_analysis = PDF::Inspector::Text.analyze(rendered_pdf)
    strings      = CvPrinter::PDFDocument.new(document: invoice).to_a

    assert_equal strings, pdf_analysis.strings
  end

  def test_render_document_from_json
    invoice           = CvPrinter::Document.new(**default_document_params)
    invoice_json      = JSON.parse(invoice.to_json)
    invoice_from_json = CvPrinter::Document.from_json(invoice_json)
    rendered_pdf      = CvPrinter.render(document: invoice_from_json)
    pdf_analysis      = PDF::Inspector::Text.analyze(rendered_pdf)
    strings           = CvPrinter::PDFDocument.new(document: invoice).to_a

    assert_equal strings, pdf_analysis.strings
  end
end
