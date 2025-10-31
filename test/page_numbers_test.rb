require 'test_helper'

class PageNumbersTest < Minitest::Test
  include CvPrinterHelpers

  # If there is only one page, we skip numbering
  def test_do_not_number_1_page
    item = CvPrinter::Document::Item.new(**default_document_item_params)
    params = default_document_params.merge(
      items: [item]
    )
    invoice = CvPrinter::Document.new(**params)
    rendered_pdf = CvPrinter.render(document: invoice)
    pdf_analysis = PDF::Inspector::Text.analyze(rendered_pdf)

    assert_equal false, pdf_analysis.strings.include?('1/1')
  end

  def test_number_2_and_more_pages
    item = CvPrinter::Document::Item.new(**default_document_item_params)
    items = [item] * 50
    params = default_document_params.merge(
      items: items
    )
    invoice = CvPrinter::Document.new(**params)
    rendered_pdf = CvPrinter.render(document: invoice)
    pdf_analysis = PDF::Inspector::Text.analyze(rendered_pdf)

    assert_equal true, pdf_analysis.strings.include?('1 / 3')
    assert_equal true, pdf_analysis.strings.include?('2 / 3')
    assert_equal true, pdf_analysis.strings.include?('3 / 3')
  end
end
