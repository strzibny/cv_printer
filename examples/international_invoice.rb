#!/usr/bin/env ruby
# This is an example of a international invoice with Czech labels and English translation.

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cv_printer'

labels = {
  name: 'Faktura',
  provider: 'Prodejce',
  purchaser: 'Kupující',
  tax_id: 'IČ',
  tax_id2: 'DIČ',
  payment: 'Forma úhrady',
  payment_by_transfer: 'Platba na následující účet:',
  account_number: 'Číslo účtu',
  issue_date: 'Datum vydání',
  due_date: 'Datum splatnosti',
  item: 'Položka',
  quantity: 'Počet',
  unit: 'MJ',
  price_per_item: 'Cena za položku',
  amount: 'Celkem bez daně',
  subtotal: 'Cena bez daně',
  tax: 'DPH 21 %',
  total: 'Celkem'
}

# Default English labels as sublabels
sublabels = CvPrinter::PDFDocument::DEFAULT_LABELS
labels.merge!({ sublabels: sublabels })

first_item = CvPrinter::Document::Item.new(
  name: 'Konzultace',
  quantity: '2',
  unit: 'hod',
  price: 'Kč 500',
  amount: 'Kč 1.000'
)

second_item = CvPrinter::Document::Item.new(
  name: 'Programování',
  quantity: '10',
  unit: 'hod',
  price: 'Kč 900',
  amount: 'Kč 9.000'
)

provider_address = <<ADDRESS
Rolnická 1
747 05  Opava
Kateřinky
ADDRESS

purchaser_address = <<ADDRESS
8648 Acacia Rd.
Brooklyn, NY 11203
ADDRESS

invoice = CvPrinter::Document.new(
  number: 'č. 198900000001',
  provider_name: 'Petr Nový',
  provider_lines: provider_address,
  provider_tax_id: '56565656',
  purchaser_name: 'Adam Black',
  purchaser_lines: purchaser_address,
  issue_date: '05/03/2016',
  due_date: '19/03/2016',
  subtotal: 'Kč 10.000',
  tax: 'Kč 2.100',
  total: 'Kč 12.100,-',
  bank_account_number: '156546546465',
  account_iban: 'IBAN464545645',
  account_swift: 'SWIFT5456',
  items: [first_item, second_item],
  note: 'Osoba je zapsána v živnostenském rejstříku.'
)

CvPrinter.print(
  document: invoice,
  labels: labels,
  font: 'overpass',
  logo: File.expand_path('../prawn.png', __FILE__),
  file_name: 'international_invoice.pdf'
)

CvPrinter.print(
  document: invoice,
  labels: labels,
  font: 'overpass',
  logo: File.expand_path('../prawn.png', __FILE__),
  file_name: 'international_invoice_a4.pdf',
  page_size: :a4
)
