require 'test_helper'

class BackgroundTest < Minitest::Test
  include CvPrinterHelpers

  def setup
    @invoice = CvPrinter::Document.new(**default_document_params)
  end

  def test_background_render
    CvPrinter.render(document: @invoice, background: './examples/background.png')
    CvPrinter.render(document: @invoice, background: nil)
    CvPrinter.render(document: @invoice)
  end

  def test_missing_background_raises_an_exception
    assert_raises(ArgumentError) do
      CvPrinter.render(document: @invoice, background: 'missing.jpg')
    end
  end
end
