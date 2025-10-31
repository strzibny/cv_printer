require 'json'
require 'cv_printer/version'
require 'cv_printer/document'
require 'cv_printer/pdf_document'

# Skip warning for not specifying TTF font
Prawn::Font::AFM.hide_m17n_warning = true

# Create PDF versions of CVs or resumes using Prawn
#
# Example:
#
#   cv = CvPrinter::Document.new(...)
#   CvPrinter.print(
#     document: cv,
#     font: 'path-to-font-file.ttf',
#     bold_font: 'path-to-font-file.ttf',
#     picture: 'picture.jpg',
#     qr: 'qr.png',
#     file_name: 'cv.pdf'
#   )
module CvPrinter
  # Override default English labels with a given hash
  def self.labels=(labels)
    PDFDocument.labels = labels
  end

  def self.labels
    PDFDocument.labels
  end

  # Print the given CvPrinter::Document to PDF file named +file_name+
  def self.print(
    document:,
    labels: {},
    font: nil,
    bold_font: nil,
    picture: nil,
    qr: nil,
    background: nil,
    page_size: :letter,
    file_name:
  )
    PDFDocument.new(
      document: document,
      labels: labels,
      font: font,
      bold_font: bold_font,
      picture: picture,
      qr: qr,
      background: background,
      page_size: page_size
    ).print(file_name)
  end

  # Render the PDF document CvPrinter::Document to PDF directly
  def self.render(
    document:,
    labels: {},
    font: nil,
    bold_font: nil,
    picture: nil,
    qr: nil,
    background: nil,
    page_size: :letter
  )
    PDFDocument.new(
      document: document,
      labels: labels,
      font: font,
      bold_font: bold_font,
      picture: picture,
      qr: qr,
      background: background,
      page_size: page_size
    ).render
  end
end
