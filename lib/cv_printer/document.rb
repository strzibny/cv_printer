module CvPrinter
  class Document
    class InvalidInput < StandardError; end

    attr_reader :name,
                :contact,
                :experience,
                :education,
                :certificates,
                :skills,
                :languages,
                :references,
                :publications,
                :awards,
                :bio

    def initialize(name: nil,
                   contact: nil,
                   experience: nil,
                   education: nil,
                   certificates: nil,
                   skills: nil,
                   languages: nil,
                   references: nil,
                   publications: nil,
                   awards: nil,
                   bio: nil)

      @name = name
      @contact = contact
      @experience = experience
      @education = education
      @certificates = certificates
      @skills = skills
      @languages = languages
      @references = references
      @publications = publications
      @awards = awards
      @bio = bio
    end
  end
end
