#!/usr/bin/env ruby
# This is an example of a simple CV.

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cv_printer'

cv = CvPrinter::Document.new(
  name: 'Josef Strzibny',
  contact: "strzibny@strzibny.name\n+420 721 313 140",
  bio: "I am a software developer with a passion for product. I love bringing ideas to life and sharing my knowledge which led me to publishing technical books.",
  experience: [
    {
      company: 'Phrase',
      position: 'Senior software engineer',
      start_date: '2022',
      end_date: '2023',
      description: 'I was mentoring junior developers and leading a couple of large team efforts.'
    },
    {
      company: 'Packeta',
      position: 'Senior software engineer',
      start_date: '2019',
      end_date: '2022',
      description: 'I was one of three engineers to build a new API platform from scratch.'
    },
    {
      company: 'Cloudaper',
      position: 'CTO',
      start_date: '2016',
      end_date: '2018',
      description: 'I led a small team as a technical hands-on CTO.'
    },
    {
      company: 'Cloudaper',
      position: 'Senior software engineer',
      start_date: '2016',
      end_date: '2016',
      description: 'I introduced automated testing and continuous integration to the team.'
    },
    {
      company: 'Red Hat',
      position: 'Software engineer',
      start_date: '2015',
      end_date: '2015',
      description: 'I maintained Ruby on Rails stack in Fedora as a Linux packager.'
    },
    {
      company: 'Red Hat',
      position: 'Associate software engineer',
      start_date: '2012',
      end_date: '2015',
      description: 'I helped with Ruby maintaintenance in Fedora and developed internal tools.'
    }
  ],
  # skills: [
  #   {
  #     name: 'Ruby on Rails',
  #     stars: 5
  #   },
  #   {
  #     name: 'JavaScript',
  #     stars: 4
  #   }
  # ],
  education: [
    {
      program: 'Master in Service Science, Management and Engineering',
      institution: 'Faculty of Informatics, Masaryk University',
      from: '2018',
      to: '2020',
      comment: ''
    },
    {
      program: 'Bachelor in Applied Informatics',
      institution: 'Faculty of Informatics, Masaryk University',
      from: '2013',
      to: '2021',
      comment: ''
    }
  ],
  publications: [
    {
      title: 'Deployment from Scratch',
      year: '2022',
    },
    {
      title: 'Kamal Handbook',
      venue: '',
      year: '2024'
    },
    {
      title: 'Test Driving Rails',
      venue: '',
      year: '2024'
    }
  ],
  references: [
    {
      name: 'Sönke Behrendt',
      position: 'Software engineer',
      company: 'Phrase',
      praise: 'Josef is an excellent developer with a lot of knowledge and experience. For many tricky Ruby questions you will find that he already has published the answer on the web.'
    },
    {
      name: 'Elizabeth Orwig',
      position: 'Software engineer',
      company: 'Phrase',
      praise: 'It was an absolute pleasure working with Josef at Phrase. He is incredibly knowledgeable and an amazing team player who I had the pleasure of pair programming with on multiple occasions.'
    }
  ]
)

CvPrinter.labels = {
  name: 'Senior software engineer',
  contact: 'Contact',
  experience: 'Experience',
  education: 'Education',
  certificates: 'Certificates',
  skills: 'Skills',
  languages: 'Languages',
  references: 'References',
  publications: 'Publications',
  awards: 'Awards',
  sublabels: {}
}

CvPrinter.print(
  document: cv,
  file_name: 'cv.pdf'
)


CvPrinter.print(
  document: cv,
  picture: File.expand_path('../profile.png', __FILE__),
  qr: File.expand_path('../qr.png', __FILE__),
  file_name: 'simple_cv.pdf'
)

CvPrinter.print(
  document: cv,
  picture: File.expand_path('../profile.png', __FILE__),
  qr: File.expand_path('../qr.png', __FILE__),
  file_name: 'simple_cv_a4.pdf',
  page_size: :a4
)
