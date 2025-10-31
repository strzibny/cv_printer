# CvPrinter Library

## Usage

There are a couple of sections that can be added to the CV beyond the name, contacts, and images. They all accept arrays of simple hashes, but different sections accept different keys.


experience

```ruby
[
  {
    position: "Software engineer",
    company: "Red Hat",
    from: "10/34/2024",
    to: "10/34/2025",
    comment: ""
  }
]
```

education

```ruby
[
  {

    program: "Software engineer",
    institution: "Red Hat",
    from: "10/34/2024",
    to: "10/34/2025",
    comment: ""
  }
]
```

certificates

skills

```ruby
[
  {
    name: "Ruby",
    stars: 5
  }
]
```

languages

```ruby
[
  {
    name: "English",
    level: "Intermediate
  }
]
```

references

```ruby
[
  {
    from: "Joe Smith",
    position: "Junior",
    company: "Red Hat",
    from: "10/34/2024",
    to: "10/34/2025",
    praise: ""
  }
]
```

publications
  
awards 

The simplest way to create your CV or resume PDF is to create a document object
and pass it to the printer:

```ruby
cv = CvPrinter::Document.new(
  ...
  experience: [item, ...]
)

CvPrinter.print(
  document: cv,
  file_name: 'cv.pdf'
)

# Or render PDF directly
CvPrinter.render(
  document: cv
)
```

Here is an full example for creating the document object:

```ruby
address = <<~ADDRESS
  Rolnická 1
  747 05  Opava
  Kateřinky
ADDRESS

cv = CvPrinter::Document.new(
  name: 'Joe Black',

)
```

### Ruby on Rails

If you want to use CvPrinter for printing PDF documents directly from Rails actions, you can:

```ruby
# GET /resumes/1
def show
  resume = CvPrinter::Document.new(...)

  respond_to do |format|
    format.pdf {
      @pdf = CvPrinter.render(
        document: resume
      )
      send_data @pdf, type: 'application/pdf', disposition: 'inline'
    }
  end
end
```


## Customization

### Page size

Both A4 and US letter is supported. Just pass `page_size` as an argument to `print` or `render` methods:

```ruby
CvPrinter.print(
  document: cv,
  labels: labels,
  page_size: :a4,
  file_name: 'cv.pdf'
)
```

`:letter` is the default.


### Localization

To localize your documents you can set both global defaults or instance
overrides:

```ruby
CvPrinter.labels = {
  skills: 'Skills',
}

labels = {
  skills: 'Znalosti',
}

CvPrinter.print(
  document: cv,
  labels: labels,
  file_name: 'cv.pdf'
)
```

Here is the full list of labels to configure. You can paste and edit this block to `initializers/cv_printer.rb` if you are using Rails.

```ruby
CvPrinter.labels = {
  name: 'Name',
  contact: 'Contact',
  experience: 'Experience',
  education: 'Education',
  certificates: 'Certificates',
  skills: 'Skills',
  languages: 'Languages',
  references: 'References',
  publications: 'Publications',
  awards: 'Awards',
}
```
**Note:** `variable`  fields lack default label. You should provide one.

You can also use sublabels feature to provide the document in two languages:

```ruby
labels = {
  ...
}

sublabels = {
  
}

labels.merge!({ sublabels: sublabels })

...
```

Now the document will have little sublabels next to the original labels in Czech.

### Font

To support specific characters you might need to specify a TTF font to be used:

```ruby
CvPrinter.print(
  ...
  font: File.expand_path('../Overpass-Regular.ttf', __FILE__)
)
```

If you don't have a font around, you can install `cv_printer_fonts` gem and specify the supported font name instead:

```ruby
CvPrinter.print(
  document: cv,
  font: "roboto"
)
```

Supported builtin fonts are: `overpass`, `opensans`, and `roboto`. Note that searching the path takes preference.

### Background

To include a background image you might need to create the file according to the size and resolution to be used (see: [examples/background.png](https://github.com/strzibny/cv_printer/blob/master/examples/background.png)):

``` ruby
CvPrinter.print(
  ...
  background: File.expand_path('../background.png', __FILE__)
)
```
