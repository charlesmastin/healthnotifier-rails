module ApplicationHelper
  def format_address(address,ste_pre=nil,line_join='<br>')
    lines = []
    if address.address_line1.present?
      lines.push(html_escape(address.address_line1))
    end
    # Unfortunately we're using line2 as suite #...
    if address.address_line2.present?
      if lines.size > 0 && ste_pre
        lines[-1] += html_escape(", #{ste_pre} #{address.address_line2}")
      else
        lines.push(html_escape("#{ste_pre ? ste_pre+' ' : ''}#{address.address_line2}"))
      end
    end
    if address.address_line3.present?
      lines.push(html_escape(address.address_line3))
    end
    s = ""
    if address.city.present?
      s += address.city
    end
    if address.state_province.present?
      s += "#{address.city.present? ? ', ' : ''}#{address.state_province}"
    end
    if address.postal_code.present?
      s += "#{address.city.present? || address.state_province.present? ? ' ' : ''}#{address.postal_code}"
    end
    if s.length > 0
      lines.push(html_escape(s))
    end
    return lines.join(line_join).html_safe
  end

  def markdown(text)
    # https://richonrails.com/articles/rendering-markdown-with-redcarpet
    options = {
      filter_html:     true,
      hard_wrap:       true, 
      link_attributes: { rel: 'nofollow', target: "_blank" },
      space_after_headers: true, 
      fenced_code_blocks: true
    }

    extensions = {
      autolink:           true,
      superscript:        true,
      disable_indented_code_blocks: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end

end
