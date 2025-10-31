#!/usr/bin/env ruby
# This is an example of a longer invoice.

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cv_printer'

labels = {
  tax: '10% VAT'
}

item = CvPrinter::Document::Item.new(
  name: 'Programming',
  quantity: '10',
  unit: 'h',
  price: '$ 60',
  tax: '$ 60',
  amount: '$ 600'
)

item2 = CvPrinter::Document::Item.new(
  name: 'Consulting',
  quantity: '10',
  unit: 'h',
  price: '$ 30',
  tax: '$ 30',
  amount: '$ 300'
)

item3 = CvPrinter::Document::Item.new(
  name: 'Support',
  quantity: '20',
  unit: 'h',
  price: '$ 15',
  tax: '$ 30',
  amount: '$ 330'
)

invoice = CvPrinter::Document.new(
  number: 'NO. 198900000001',
  provider_name: 'John White',
  provider_lines: "79 Stonybrook St.\nBronx, NY 10457",
  purchaser_name: 'Will Black',
  purchaser_lines: "8648 Acacia Rd.\nBrooklyn, NY 11203",
  issue_date: '05/03/2016',
  due_date: '19/03/2016',
  subtotal: '$ 1,000',
  tax: '$ 100',
  total: '$ 1,100',
  bank_account_number: '156546546465',
  items: [item, item2, item3] * 20,
  note: 'This is a note at the end.'
)

CvPrinter.print(
  document: invoice,
  labels: labels,
  stamp: File.expand_path('../stamp.png', __FILE__),
  logo: File.expand_path('../prawn.png', __FILE__),
  file_name: 'long_invoice.pdf'
)

CvPrinter.print(
  document: invoice,
  labels: labels,
  stamp: File.expand_path('../stamp.png', __FILE__),
  logo: File.expand_path('../prawn.png', __FILE__),
  file_name: 'long_invoice_a4.pdf',
  page_size: :a4
)
