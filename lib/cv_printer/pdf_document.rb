require 'prawn'
require 'prawn/table'

module CvPrinter
  # Prawn PDF representation of CvPrinter::Document
  class PDFDocument
    class FontFileNotFound < StandardError; end
    class ProfileFileNotFound < StandardError; end
    class QRFileNotFound < StandardError; end
    class InvalidInput < StandardError; end

    attr_reader :cv, :labels, :file_name, :font, :bold_font, :picture, :qr

    DEFAULT_LABELS = {
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
      sublabels: {}
    }

    PageSize = Struct.new(:name, :width, :height)

    PAGE_SIZES = {
      letter: PageSize.new('LETTER', 612.00, 792.00),
      a4:     PageSize.new('A4', 595.28, 841.89),
    }

    def self.labels
      @@labels ||= DEFAULT_LABELS
    end

    def build_content_columns
      # Establish two-column layout below the header
      top_y = @pdf.cursor
      total_w = @pdf.bounds.width
      gutter = 12
      left_w = ((total_w - gutter) * 2.0 / 3.0)
      right_w = total_w - gutter - left_w
      height = top_y
      pad = 10

      right_x = left_w + gutter
      inner_width = right_w - (2 * pad)
      @sidebar_pad = 2
      @other_padding_applied = false
      bio_cushion = 0
      other_cushion = 12
      section_gap = 8

      bio_height = measure_bio_height(inner_width)
      other_height = measure_right_sidebar_height(inner_width)

      bio_total_bg   = bio_height.positive? ? bio_height + (2 * pad) + bio_cushion : 0
      other_total_bg = other_height.positive? ? other_height + (2 * pad) + other_cushion : 0

      start_page = @pdf.page_number
      page_h = @pdf.margin_box.height

      # Draw first page background for BIO
      bio_draw_first = 0
      if bio_total_bg > 0
        bio_draw_first = [bio_total_bg, top_y].min
        @pdf.save_graphics_state
        @pdf.stroke_color 'aaaaaa'
        @pdf.stroke do
          @pdf.rounded_rectangle([right_x, top_y], right_w, bio_draw_first, 6)
        end
        @pdf.restore_graphics_state
      end

      # Compute where the OTHER section starts (page and y) and draw its first-page background if it starts on page 1
      rem_bio = bio_total_bg - bio_draw_first
      other_start_page = start_page
      other_start_y = top_y - bio_draw_first - section_gap
      if rem_bio > 0
        full_pages = (rem_bio / page_h).floor
        remainder  = rem_bio % page_h
        if remainder > 0
          other_start_page = start_page + full_pages + 1
          # starts mid-page on that page, y will be computed when drawing after content
        else
          other_start_page = start_page + full_pages + 1
        end
      end

      if other_total_bg > 0 && other_start_page == start_page && other_start_y > 0
        other_draw_first = [other_total_bg, other_start_y].min
        @pdf.save_graphics_state
        @pdf.fill_color 'f3f3f3'
        @pdf.fill do
          @pdf.rounded_rectangle([right_x, other_start_y], right_w, other_draw_first, 6)
        end
        @pdf.restore_graphics_state
        @pdf.fill_color '000000'
      end

      @pdf.bounding_box([0, top_y], width: left_w, height: @pdf.bounds.height) do
        build_experiences
        build_education
        build_publications
      end

      @pdf.bounding_box([right_x + pad, top_y - pad], width: inner_width, height: @pdf.bounds.height - pad) do
        build_bio
        build_skills
        build_languages
        build_references
      end

      # Draw overflow backgrounds AFTER content for BIO and OTHER
      # BIO overflow
      if bio_total_bg > bio_draw_first && @pdf.page_count >= start_page
        remaining = bio_total_bg - bio_draw_first
        (1..((remaining.to_f / page_h).ceil)).each do |i|
          pg = start_page + i
          break if pg > @pdf.page_count
          @pdf.go_to_page(pg)
          x_abs = @pdf.margin_box.absolute_left + right_x
          y_top = @pdf.margin_box.absolute_top
          draw_h = [remaining, page_h].min
          @pdf.canvas do
            @pdf.stroke_color 'aaaaaa'
            @pdf.stroke { @pdf.rectangle [x_abs, y_top], right_w, draw_h }
          end
          remaining -= draw_h
        end
      end

      # OTHER overflow
      if other_total_bg > 0
        # Determine first draw height on the start page for OTHER
        if other_start_page == start_page
          first_draw_other = [other_total_bg, other_start_y].min
          remaining_other = other_total_bg - first_draw_other
        else
          # other starts later (after BIO spans full/partial pages)
          # compute remainder height of BIO on start page for OTHER if any
          rem_bio_after_first = rem_bio
          full_pages = (rem_bio_after_first / page_h).floor
          remainder  = rem_bio_after_first % page_h
          remaining_other = other_total_bg
        end

        # Draw on subsequent pages for OTHER
        if @pdf.page_count >= other_start_page
          # If starting mid-page after BIO remainder, adjust first draw height accordingly
          page_index = other_start_page
          if page_index <= @pdf.page_count
            @pdf.go_to_page(page_index)
            x_abs = @pdf.margin_box.absolute_left + right_x
            y_top = @pdf.margin_box.absolute_top
            # If OTHER starts mid-page due to BIO remainder, compute start y
            start_y_on_page = if other_start_page == start_page
                                other_start_y
                              else
                                # mid-page if BIO has remainder, otherwise top of page
                                remainder_bio = rem_bio % page_h
                                remainder_bio > 0 ? (y_top - remainder_bio - section_gap) : y_top
                              end
            draw_h = [remaining_other, start_y_on_page].min
            if draw_h > 0
              @pdf.canvas do
                @pdf.fill_color 'f3f3f3'
                @pdf.fill { @pdf.rounded_rectangle [x_abs, start_y_on_page], right_w, draw_h, 6 }
                @pdf.fill_color '000000'
              end
            end
            remaining_other -= draw_h
          end

          # Next pages
          while remaining_other > 0
            page_index += 1
            break if page_index > @pdf.page_count
            @pdf.go_to_page(page_index)
            x_abs = @pdf.margin_box.absolute_left + right_x
            y_top = @pdf.margin_box.absolute_top
            draw_h = [remaining_other, page_h].min
            @pdf.canvas do
              @pdf.fill_color 'f3f3f3'
              @pdf.fill { @pdf.rectangle [x_abs, y_top], right_w, draw_h }
              @pdf.fill_color '000000'
            end
            remaining_other -= draw_h
          end
        end
      end
    end

    def measure_right_sidebar_height(inner_width)
      total = 0

      if @document.respond_to?(:skills) && @document.skills && !@document.skills.empty?
        total += @pdf.height_of(@labels[:skills].to_s, size: 14, width: inner_width)
        total += 6
        @document.skills.each do |skill|
          name = skill.is_a?(Hash) ? value_for(skill, :name) : skill
          next if name.nil? || name.to_s.strip.empty?
          total += @pdf.height_of(name.to_s, size: 10, width: inner_width)
        end
      end

      if @document.respond_to?(:languages) && @document.languages && !@document.languages.empty?
        total += 12 unless total.zero?
        total += @pdf.height_of(@labels[:languages].to_s, size: 14, width: inner_width)
        total += 6
        @document.languages.each do |lang|
          name = level = nil
          if lang.is_a?(Hash)
            name  = value_for(lang, :name)
            level = value_for(lang, :level)
          else
            name = lang
          end
          next if name.nil? || name.to_s.strip.empty?
          line = name.to_s
          line += " - #{level}" if level && !level.to_s.strip.empty?
          total += @pdf.height_of(line, size: 10, width: inner_width)
        end
      end

      if @document.respond_to?(:references) && @document.references && !@document.references.empty?
        total += 2 unless total.zero?
        total += @pdf.height_of(@labels[:references].to_s, size: 14, width: inner_width)
        total += 6
        @document.references.each do |ref|
          praise   = value_for(ref, :praise) || value_for(ref, :comment)
          name     = value_for(ref, :name)
          position = value_for(ref, :position)
          company  = value_for(ref, :company)
          if praise && !praise.to_s.strip.empty?
            total += @pdf.height_of(praise.to_s, size: 10, width: inner_width)
            if (name && !name.to_s.strip.empty?) || (position && !position.to_s.strip.empty?) || (company && !company.to_s.strip.empty?)
              total += 6
            end
          end
          if name && !name.to_s.strip.empty?
            total += @pdf.height_of(name.to_s, size: 10, width: inner_width)
          end
          pos_company = [position, company].map { |v| v.to_s.strip }.reject(&:empty?).join(', ')
          unless pos_company.empty?
            total += @pdf.height_of(pos_company, size: 10, width: inner_width)
          end
          total += 8
        end
      end

      total
    end

    def measure_bio_height(inner_width)
      return 0 unless @document.respond_to?(:bio) && @document.bio && !@document.bio.to_s.strip.empty?
      height = @pdf.height_of(@document.bio.to_s, size: 10, width: inner_width)
      if used?(@qr)
        qr_side = [x(50), inner_width].min
        height += 8
        height += qr_side
        height += 6
      end
      height
    end

    def ensure_other_top_padding
      return false if @other_padding_applied
      space = @sidebar_pad || 10
      @pdf.move_down(space)
      @other_padding_applied = true
      true
    end

    # overflow background handled by repeat above

    def build_skills
      return unless @document.respond_to?(:skills) && @document.skills && !@document.skills.empty?

      ensure_other_top_padding
      @pdf.text(@labels[:skills], size: 14)
      @pdf.move_down(6)

      @document.skills.each do |skill|
        name = if skill.is_a?(Hash)
                 value_for(skill, :name)
               else
                 skill
               end
        next if name.nil? || name.to_s.strip.empty?
        @pdf.text(name.to_s, size: 10)
      end
    end

    def build_languages
      return unless @document.respond_to?(:languages) && @document.languages && !@document.languages.empty?

      applied = ensure_other_top_padding
      @pdf.move_down(4) unless applied
      @pdf.text(@labels[:languages], size: 14)
      @pdf.move_down(6)

      @document.languages.each do |lang|
        name = level = nil
        if lang.is_a?(Hash)
          name  = value_for(lang, :name)
          level = value_for(lang, :level)
        else
          name = lang
        end
        next if name.nil? || name.to_s.strip.empty?

        line = name.to_s
        line += " - #{level}" if level && !level.to_s.strip.empty?
        @pdf.text(line, size: 10)
      end
    end

    def build_bio
      return unless @document.respond_to?(:bio) && @document.bio && !@document.bio.to_s.strip.empty?

      @pdf.text(@document.bio.to_s, size: 10, leading: 2)
      if used?(@qr)
        @pdf.move_down(8)
        qr_side = [x(50), @pdf.bounds.width].min
        @pdf.image(@qr, fit: [qr_side, qr_side], position: :center)
        @pdf.move_down(6)
        @qr_consumed = true
      end
      @pdf.move_down(12)
    end

    def build_experiences
      return unless @document.respond_to?(:experience) && @document.experience && !@document.experience.empty?

      @pdf.move_down(10)
      @pdf.text(@labels[:experience], size: 16)
      @pdf.move_down(2)
      @pdf.save_graphics_state
      @pdf.stroke_color '000000'
      @pdf.stroke_horizontal_rule
      @pdf.restore_graphics_state
      @pdf.move_down(6)

      @document.experience.each do |exp|
        position = value_for(exp, :position)
        company  = value_for(exp, :company)
        from     = value_for(exp, :from) || value_for(exp, :start_date)
        to       = value_for(exp, :to) || value_for(exp, :end_date)
        desc     = value_for(exp, :description)

        fragments = []
        if position && !position.to_s.strip.empty?
          fragments << { text: position.to_s, styles: [:bold] }
        end
        if company && !company.to_s.strip.empty?
          fragments << { text: ', ' } unless fragments.empty?
          fragments << { text: company.to_s }
        end

        date_span = [from, to].compact.map { |v| v.to_s.strip }.reject(&:empty?).join('—')
        @pdf.formatted_text(fragments, size: 12) unless fragments.empty?
        if !date_span.empty?
          @pdf.text(date_span, size: 10)
        end
        if desc && !desc.to_s.strip.empty?
          @pdf.text(desc.to_s, size: 10, leading: 2)
        end
        @pdf.move_down(8)
      end
    end

    def build_contact
      return unless @document.respond_to?(:contact) && @document.contact && !@document.contact.to_s.strip.empty?

      @pdf.move_down(10)
      @pdf.text(@labels[:contact], size: 14)
      @pdf.move_down(6)
      @pdf.text(@document.contact.to_s, size: 10, leading: 2)
    end

    def build_education
      return unless @document.respond_to?(:education) && @document.education && !@document.education.empty?

      @pdf.move_down(10)
      @pdf.text(@labels[:education], size: 16)
      @pdf.move_down(2)
      @pdf.save_graphics_state
      @pdf.stroke_color '000000'
      @pdf.stroke_horizontal_rule
      @pdf.restore_graphics_state
      @pdf.move_down(6)

      @document.education.each do |edu|
        program     = value_for(edu, :program)
        institution = value_for(edu, :institution)
        from        = value_for(edu, :from) || value_for(edu, :start_date)
        to          = value_for(edu, :to) || value_for(edu, :end_date)
        comment     = value_for(edu, :comment) || value_for(edu, :description)

        date_span = [from, to].compact.map { |v| v.to_s.strip }.reject(&:empty?).join('—')

        if program && !program.to_s.strip.empty?
          @pdf.text(program.to_s, size: 12)
        end

        details_parts = []
        details_parts << date_span unless date_span.empty?
        details_parts << institution.to_s.strip unless institution.nil? || institution.to_s.strip.empty?
        details_line = details_parts.join(', ')
        @pdf.text(details_line, size: 10) unless details_line.to_s.strip.empty?

        if comment && !comment.to_s.strip.empty?
          @pdf.text(comment.to_s, size: 10, leading: 2)
        end
        @pdf.move_down(8)
      end
    end

    def build_publications
      return unless @document.respond_to?(:publications) && @document.publications && !@document.publications.empty?

      @pdf.move_down(10)
      @pdf.text(@labels[:publications], size: 16)
      @pdf.move_down(2)
      @pdf.save_graphics_state
      @pdf.stroke_color '000000'
      @pdf.stroke_horizontal_rule
      @pdf.restore_graphics_state
      @pdf.move_down(6)

      @document.publications.each do |pub|
        title = value_for(pub, :title)
        venue = value_for(pub, :venue)
        year  = value_for(pub, :year)
        link  = value_for(pub, :link) || value_for(pub, :url)

        @pdf.text(title.to_s, size: 12) if title && !title.to_s.strip.empty?
        details_parts = []
        details_parts << venue if venue && !venue.to_s.strip.empty?
        details_parts << year if year && !year.to_s.strip.empty?
        details_line = details_parts.join(', ')
        @pdf.text(details_line, size: 10) unless details_line.to_s.strip.empty?
        @pdf.text(link.to_s, size: 10) if link && !link.to_s.strip.empty?
        @pdf.move_down(8)
      end
    end

    def build_references
      return unless @document.respond_to?(:references) && @document.references && !@document.references.empty?

      applied = ensure_other_top_padding
      @pdf.move_down(2) unless applied
      @pdf.text(@labels[:references], size: 14)
      @pdf.move_down(6)

      @document.references.each do |ref|
        praise   = value_for(ref, :praise) || value_for(ref, :comment)
        name     = value_for(ref, :name)
        position = value_for(ref, :position)
        company  = value_for(ref, :company)
        if praise && !praise.to_s.strip.empty?
          @pdf.formatted_text([{ text: praise.to_s, styles: [:italic] }], size: 10, leading: 2)
          if (name && !name.to_s.strip.empty?) || (position && !position.to_s.strip.empty?) || (company && !company.to_s.strip.empty?)
            @pdf.move_down(6)
          end
        end
        if name && !name.to_s.strip.empty?
          @pdf.fill_color '666666'
          @pdf.text(name.to_s, size: 10)
          @pdf.fill_color '000000'
        end
        pos_company = [position, company].map { |v| v.to_s.strip }.reject(&:empty?).join(', ')
        unless pos_company.empty?
          @pdf.fill_color '666666'
          @pdf.text(pos_company, size: 10)
          @pdf.fill_color '000000'
        end
        @pdf.move_down(8)
      end
    end

    def self.labels=(labels)
      @@labels = DEFAULT_LABELS.merge(labels)
    end

    def initialize(
      document: Document.new,
      labels: {},
      font: nil,
      bold_font: nil,
      stamp: nil,
      picture: nil,
      qr: nil,
      background: nil,
      page_size: :letter
    )
      @document  = document
      @labels    = merge_custom_labels(labels)
      @font      = font
      @bold_font = bold_font
      @stamp     = stamp
      @picture   = picture
      @qr        = qr
      @page_size = page_size ? PAGE_SIZES[page_size.to_sym] : PAGE_SIZES[:letter]
      @pdf       = Prawn::Document.new(background: background, page_size: @page_size.name)

      raise InvalidInput, 'document is not a type of CvPrinter::Document' \
        unless @document.is_a?(CvPrinter::Document)

      if used? @picture
        if File.exist?(@picture)
          @picture = picture
        else
          raise ProfileFileNotFound, "Profile file not found at #{@picture}"
        end
      end

      if used? @qr
        if File.exist?(@qr)
          @qr = qr
        else
          raise QRFileNotFound, "QR image file not found at #{@qr}"
        end
      end

      if used?(@font) && used?(@bold_font)
        use_font(@font, @bold_font)
      elsif used?(@font)
        use_font(@font, @font)
      end

      build_pdf
    end

    # Create PDF file named +file_name+
    def print(file_name = 'cv.pdf')
      @pdf.render_file file_name
    end

    # Directly render the PDF
    def render
      @pdf.render
    end

    private

    def use_font(font, bold_font)
      if File.exist?(font) && File.exist?(bold_font)
        set_font_from_path(font, bold_font)
      else
        set_builtin_font(font)
      end
    end

    def set_builtin_font(font)
      # Keep using the existing fonts namespaced under CvPrinter for now
      require 'cv_printer/fonts'

      @pdf.font_families.update(
        "#{font}" => CvPrinter::Fonts.paths_for(font)
      )
      @pdf.font(font)

    rescue StandardError
      raise FontFileNotFound, "Font file not found for #{font}"
    end

    # Add font family in Prawn for a given +font+ file
    def set_font_from_path(font, bold_font)
      font_name = Pathname.new(font).basename
      @pdf.font_families.update(
        "#{font_name}" => {
          normal: font,
          italic: font,
          bold: bold_font,
          bold_italic: bold_font
        }
      )
      @pdf.font(font_name)
    end

    # Build the PDF version of the document (@pdf)
    def build_pdf
      @push_down = 0
      @push_items_table = 0
      @qr_consumed = false
      @pdf.fill_color '000000'
      @pdf.stroke_color 'aaaaaa'
      build_header
      build_content_columns
      build_qr
      build_footer
    end

    def build_header
      @pdf.text_box(
        @document.name,
        size: 32,
        align: :left,
        at: [75, y(720) - @push_down - 10],
        width: x(300),
      )

      if used? @labels[:name]
        @pdf.text_box(
          @labels[:name],
          size: 12,
          at: [75, y(720) - @push_down - 42],
          width: x(300),
          align: :left
        )
      end

      if @document.respond_to?(:contact) && @document.contact && !@document.contact.to_s.strip.empty?
        offset = used?(@labels[:name]) ? 72 : 72
        @pdf.text_box(
          @document.contact.to_s,
          size: 10,
          at: [0, y(720) - @push_down - offset],
          width: x(300),
          align: :left
        )
      end

      if used?(@picture)
        left = @pdf.bounds.right - x(60)
        top  = y(720) - @push_down
        @pdf.image(@picture, at: [0, top], fit: [x(60), y(60)])
      end

      @pdf.move_down(100)
      # if used? @labels[:sublabels][:name]
      #   @pdf.move_down(12)
      # end
    end

    # def build_provider_box
    #   @pdf.text_box(
    #     @document.provider_name,
    #     size: 15,
    #     at: [10, y(640) - @push_down],
    #     width: x(220)
    #   )
    #   @pdf.text_box(
    #     @labels[:provider],
    #     size: 11,
    #     at: [10, y(660) - @push_down],
    #     width: x(240)
    #   )
    #   if used? @labels[:sublabels][:provider]
    #     @pdf.text_box(
    #       @labels[:sublabels][:provider],
    #       size: 10,
    #       at: [10, y(660) - @push_down],
    #       width: x(246),
    #       align: :right
    #     )
    #   end
    #   if !@document.provider_lines.empty?
    #     @pdf.text_box(
    #       @document.provider_lines,
    #       size: 10,
    #       at: [x(10), y(618) - @push_down],
    #       width: x(246),
    #       height: y(68),
    #       leading: 3,
    #     )
    #   end
    #   unless @document.provider_tax_id.empty?
    #     @pdf.text_box(
    #       "#{@labels[:tax_id]}:    #{@document.provider_tax_id}",
    #       size: 10,
    #       at: [10, y(550) - @push_down],
    #       width: x(240)
    #     )
    #   end
    #   unless @document.provider_tax_id2.empty?
    #     @pdf.text_box(
    #       "#{@labels[:tax_id2]}:    #{@document.provider_tax_id2}",
    #       size: 10,
    #       at: [10, y(535) - @push_down],
    #       width: x(240)
    #     )
    #   end
    #   @pdf.stroke_rounded_rectangle([0, y(670) - @push_down], x(266), y(150), 6)
    # end

    # def build_purchaser_box
    #   purchaser = [@document.purchaser_name, @document.purchaser_lines].join("\n")

    #   @pdf.text_box(
    #     purchaser.lines.first,
    #     size: 15,
    #     at: [x(284), y(640) - @push_down],
    #     width: x(240)
    #   )
    #   @pdf.text_box(
    #     @labels[:purchaser],
    #     size: 11,
    #     at: [x(284), y(660) - @push_down],
    #     width: x(240)
    #   )

    #   if used? @labels[:sublabels][:purchaser]
    #     @pdf.text_box(
    #       @labels[:sublabels][:purchaser],
    #       size: 10,
    #       at: [10, y(660) - @push_down],
    #       width: x(520),
    #       align: :right
    #     )
    #   end
    #   if purchaser.lines.size > 1
    #     @pdf.text_box(
    #       purchaser.lines(chomp: true)[1..].join("\n"),
    #       size: 10,
    #       at: [x(284), y(618) - @push_down],
    #       width: x(246),
    #       height: y(68),
    #       leading: 3,
    #     )
    #   end
    #   unless @document.purchaser_tax_id.empty?
    #     @pdf.text_box(
    #       "#{@labels[:tax_id]}:    #{@document.purchaser_tax_id}",
    #       size: 10,
    #       at: [x(284), y(550) - @push_down],
    #       width: x(240)
    #     )
    #   end
    #   unless @document.purchaser_tax_id2.empty?
    #     @pdf.text_box(
    #       "#{@labels[:tax_id2]}:    #{@document.purchaser_tax_id2}",
    #       size: 10,
    #       at: [x(284), y(535) - @push_down],
    #       width: x(240)
    #     )
    #   end
    #   @pdf.stroke_rounded_rectangle([x(274), y(670) - @push_down], x(266), y(150), 6)
    # end

    # def build_payment_method_box
    #   @push_down -= 3

    #   unless letter?
    #     @push_items_table += 18
    #   end

    #   min_height = 60
    #   if used?(@document.issue_date) || used?(@document.due_date)
    #     min_height = (used?(@document.issue_date) && used?(@document.due_date)) ? 75 : 60
    #   end
    #   @payment_box_height = min_height

    #   if big_info_box?
    #     @payment_box_height = 110
    #   end

    #   if @document.bank_account_number.empty?
    #     @pdf.text_box(
    #       @labels[:payment],
    #       size: 10,
    #       at: [10, y(498) - @push_down],
    #       width: x(234)
    #     )
    #     @pdf.text_box(
    #       @labels[:payment_in_cash],
    #       size: 10,
    #       at: [10, y(483) - @push_down],
    #       width: x(234)
    #     )

    #     @pdf.stroke_rounded_rectangle([0, y(508) - @push_down], x(266), @payment_box_height, 6)
    #   else
    #     @payment_box_height = 60
    #     @push_iban = 0
    #     sublabel_change = 0
    #     @pdf.text_box(
    #       @labels[:payment_by_transfer],
    #       size: 10,
    #       at: [10, y(498) - @push_down],
    #       width: x(234)
    #     )
    #     @pdf.text_box(
    #       "#{@labels[:account_number]}",
    #       size: 11,
    #       at: [10, y(483) - @push_down],
    #       width: x(134)
    #     )
    #     @pdf.text_box(
    #       @document.bank_account_number,
    #       size: 13,
    #       at: [21, y(483) - @push_down],
    #       width: x(234),
    #       align: :right
    #     )
    #     if used? @labels[:sublabels][:account_number]
    #       @pdf.text_box(
    #         "#{@labels[:sublabels][:account_number]}",
    #         size: 10,
    #         at: [10, y(468) - @push_down],
    #         width: x(334)
    #       )
    #     else
    #       @payment_box_height -= 10
    #       sublabel_change -= 10
    #     end
    #     unless @document.account_swift.empty?
    #       @pdf.text_box(
    #         "#{@labels[:swift]}",
    #         size: 11,
    #         at: [10, y(453) - @push_down - sublabel_change],
    #         width: x(134)
    #       )
    #       @pdf.text_box(
    #         @document.account_swift,
    #         size: 13,
    #         at: [21, y(453) -  @push_down - sublabel_change],
    #         width: x(234),
    #         align: :right
    #       )

    #       if used? @labels[:sublabels][:swift]
    #         @pdf.text_box(
    #           "#{@labels[:sublabels][:swift]}",
    #           size: 10,
    #           at: [10, y(438) - @push_down - sublabel_change],
    #           width: x(334)
    #         )
    #         @push_items_table += 10
    #       else
    #         @payment_box_height -= 10
    #         sublabel_change -= 10
    #       end

    #       @payment_box_height += 30
    #       @push_iban = 30
    #       @push_items_table += 18
    #     end
    #     unless @document.account_iban.empty?
    #       @pdf.text_box(
    #         "#{@labels[:iban]}",
    #         size: 11,
    #         at: [10, y(453) - @push_iban - @push_down - sublabel_change],
    #         width: x(134)
    #       )
    #       @pdf.text_box(
    #         @document.account_iban,
    #         size: 13,
    #         at: [21, y(453) - @push_iban - @push_down - sublabel_change],
    #         width: x(234),
    #         align: :right
    #       )

    #       if used? @labels[:sublabels][:iban]
    #         @pdf.text_box(
    #           "#{@labels[:sublabels][:iban]}",
    #           size: 10,
    #           at: [10, y(438) - @push_iban - @push_down - sublabel_change],
    #           width: x(334)
    #         )
    #         @push_items_table += 10
    #       else
    #         @payment_box_height -= 10
    #       end

    #       @payment_box_height += 30
    #       @push_items_table += 18
    #     end

    #     if min_height > @payment_box_height
    #       @payment_box_height = min_height
    #       @push_items_table += 25
    #     end

    #     if !@document.account_swift.empty? && !@document.account_iban.empty?
    #       @push_items_table += 2
    #     end

    #     @pdf.stroke_rounded_rectangle([0, y(508) - @push_down], x(266), @payment_box_height, 6)
    #   end
    # end

    # def big_info_box?
    #   !@document.issue_date.empty? &&
    #   !@document.due_date.empty? &&
    #   !@document.variable_symbol.empty? &&
    #   info_box_sublabels_used?
    # end

    # def info_box_sublabels_used?
    #   used?(@labels[:sublabels][:issue_date]) ||
    #   used?(@labels[:sublabels][:due_date]) ||
    #   used?(@labels[:sublabels][:variable_symbol])
    # end

    # def build_description
    #   unless @document.description.empty?
    #     @pdf.text_box(
    #       @document.description,
    #       size: 11,
    #       align: :left,
    #       at: [0, y(450) - @push_down - 26]
    #     )
    #     @push_items_table += description_height + 8
    #   end
    # end

    # def description_height
    #   @description_height ||= begin
    #     num_of_lines = @document.description.lines.count
    #     (num_of_lines * 13)
    #   end
    # end

    # def build_items
    #   @pdf.move_down(23 + @push_items_table + @push_down)

    #   items_params = determine_items_structure
    #   items = build_items_data(items_params)
    #   headers = build_items_header(items_params)
    #   data = items.prepend(headers)

    #   options = {
    #     header: true,
    #     width: x(540, 2),
    #     cell_style: {
    #       borders: []
    #     }
    #   }

    #   unless items.empty?
    #     @pdf.font_size(10) do
    #       @pdf.table(data, options) do
    #         row(0).background_color = 'e3e3e3'
    #         row(0).border_color = 'aaaaaa'
    #         row(0).borders = [:bottom]
    #         row(items.size - 1).borders = [:bottom]
    #         row(items.size - 1).border_color = 'd9d9d9'
    #       end
    #     end
    #   end
    # end

    # def determine_items_structure
    #   items_params = {}
    #   @document.items.each do |item|
    #     items_params[:names] = true unless item.name.empty?
    #     items_params[:variables] = true unless item.variable.empty?
    #     items_params[:quantities] = true unless item.quantity.empty?
    #     items_params[:units] = true unless item.unit.empty?
    #     items_params[:prices] = true unless item.price.empty?
    #     items_params[:taxes] = true unless item.tax.empty?
    #     items_params[:taxes2] = true unless item.tax2.empty?
    #     items_params[:taxes3] = true unless item.tax3.empty?
    #     items_params[:amounts] = true unless item.amount.empty?
    #   end
    #   items_params
    # end

    # def build_items_data(items_params)
    #   colspan = items_params.select { |k, v| v }.count
    #   color_background = false

    #   items = []
    #   @document.items.each do |item|
    #     line = []
    #     line << { content: item.name, align: :left } if items_params[:names]
    #     line << { content: item.variable, align: :right } if items_params[:variables]
    #     line << { content: item.quantity, align: :right } if items_params[:quantities]
    #     line << { content: item.unit, align: :right } if items_params[:units]
    #     line << { content: item.price, align: :right } if items_params[:prices]
    #     line << { content: item.tax, align: :right } if items_params[:taxes]
    #     line << { content: item.tax2, align: :right } if items_params[:taxes2]
    #     line << { content: item.tax3, align: :right } if items_params[:taxes3]
    #     line << { content: item.amount, align: :right } if items_params[:amounts]

    #     line.each {|c| c[:background_color] = 'ededed'} if color_background

    #     items << line

    #     if used?(item.breakdown)
    #       items << [{ content: item.breakdown, align: :left, size: 8, colspan: colspan, padding: [0, 0, 5, 5] }]
    #       items.last.first[:background_color] = 'ededed' if color_background
    #     end

    #     color_background = !color_background
    #   end
    #   items
    # end

    # def build_items_header(items_params)
    #   headers = []
    #   headers << { content: label_with_sublabel(:item), align: :left } if items_params[:names]
    #   headers << { content: label_with_sublabel(:variable), align: :right } if items_params[:variables]
    #   headers << { content: label_with_sublabel(:quantity), align: :right } if items_params[:quantities]
    #   headers << { content: label_with_sublabel(:unit), align: :right } if items_params[:units]
    #   headers << { content: label_with_sublabel(:price_per_item), align: :right } if items_params[:prices]
    #   headers << { content: label_with_sublabel(:tax), align: :right } if items_params[:taxes]
    #   headers << { content: label_with_sublabel(:tax2), align: :right } if items_params[:taxes2]
    #   headers << { content: label_with_sublabel(:tax3), align: :right } if items_params[:taxes3]
    #   headers << { content: label_with_sublabel(:amount), align: :right } if items_params[:amounts]
    #   headers
    # end

    # def label_with_sublabel(symbol)
    #   value = @labels[symbol]
    #   if used? @labels[:sublabels][symbol]
    #     value += "\n#{@labels[:sublabels][symbol]}"
    #   end
    #   value
    # end

    # def build_total
    #   @pdf.move_down(25)

    #   items = []

    #   items << [
    #     { content: "#{@labels[:subtotal]}:#{build_sublabel_for_total_table(:subtotal)}", align: :left },
    #     { content: @document.subtotal, align: :right }
    #   ] unless @document.subtotal.empty?

    #   items << [
    #     { content: "#{@labels[:tax]}:#{build_sublabel_for_total_table(:tax)}", align: :left },
    #     { content:  @document.tax, align: :right }
    #   ] unless @document.tax.empty?

    #   items << [
    #     { content: "#{@labels[:tax2]}:#{build_sublabel_for_total_table(:tax2)}", align: :left },
    #     { content:  @document.tax2, align: :right }
    #   ] unless @document.tax2.empty?

    #   items << [
    #     { content: "#{@labels[:tax3]}:#{build_sublabel_for_total_table(:tax3)}", align: :left },
    #     { content:  @document.tax3, align: :right }
    #   ] unless @document.tax3.empty?

    #   items << [
    #     { content: "\n#{@labels[:total]}:#{build_sublabel_for_total_table(:total)}", align: :left, font_style: :bold, size: 16 },
    #     { content:  "\n#{@document.total}", align: :right, font_style: :bold, size: 16 }
    #   ] unless @document.total.empty?

    #   options = {
    #     cell_style: {
    #       borders: []
    #     },
    #     position: :right
    #   }

    #   @pdf.table(items, options) unless items.empty?
    # end

    # def build_sublabel_for_total_table(sublabel)
    #   if used? @labels[:sublabels][sublabel]
    #     "\n#{@labels[:sublabels][sublabel]}:"
    #   else
    #     ''
    #   end
    # end

    def build_picture
      return unless used?(@picture)

      last_page = @pdf.page_count
      @pdf.go_to_page(1) if last_page >= 1
      left = @pdf.bounds.right - x(50)
      top  = @pdf.bounds.top
      @pdf.image(@picture, at: [0, top], fit: [x(50), y(50)])
      @pdf.go_to_page(last_page)
    end

    def build_qr
      return if @qr_consumed
      return unless used?(@qr)
    end

    def build_footer
      @pdf.number_pages(
        '<page> / <total>',
        start_count_at: 1,
        at: [@pdf.bounds.right - 50, 0],
        align: :right,
        size: 12
      ) unless @pdf.page_count == 1
    end

    def used?(element)
      element && !element.empty?
    end

    def value_for(hash, key)
      return nil unless hash.respond_to?(:[]) || hash.respond_to?(:fetch)
      hash[key] || hash[key.to_s]
    end

    def letter?
      @page_size.name == 'LETTER'
    end

    def x(value, adjust = 1)
      return value if letter?

      width_ratio = value / PAGE_SIZES[:letter].width
      (width_ratio * @page_size.width) - adjust
    end

    def y(value)
      return value if letter?

      width_ratio = value / PAGE_SIZES[:letter].height
      width_ratio * @page_size.height
    end

    def merge_custom_labels(labels = {})
      custom_labels = if labels
                        hash_keys_to_symbols(labels)
                      else
                        {}
                      end

      PDFDocument.labels.merge(custom_labels)
    end

    def hash_keys_to_symbols(value)
      return value unless value.is_a? Hash

      value.inject({}) do |memo, (k, v)|
        memo[k.to_sym] = hash_keys_to_symbols(v)
        memo
      end
    end
  end
end
