require 'test_helper'

class LabelsTest < Minitest::Test
  include CvPrinterHelpers

  def test_setting_global_labels
    labels = { provider: 'Default Provider', purchaser: 'Default Purchaser' }
    CvPrinter.labels = labels
    invoice = CvPrinter::Document.new(**default_document_params)
    rendered_pdf = CvPrinter.render(document: invoice)
    pdf_analysis = PDF::Inspector::Text.analyze(rendered_pdf)

    assert_equal true, pdf_analysis.strings.include?('Default Provider')
    assert_equal true, pdf_analysis.strings.include?('Default Purchaser')
  end

  def test_setting_instant_labels
    labels = { provider: 'Current Provider', purchaser: 'Current Purchaser' }
    invoice = CvPrinter::Document.new(**default_document_params)
    rendered_pdf = CvPrinter.render(document: invoice, labels: labels)
    pdf_analysis = PDF::Inspector::Text.analyze(rendered_pdf)

    assert_equal true, pdf_analysis.strings.include?('Current Provider')
    assert_equal true, pdf_analysis.strings.include?('Current Purchaser')
  end
end
