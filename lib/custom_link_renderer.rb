class CustomLinkRenderer < WillPaginate::LinkRenderer

  def to_html
    links = @options[:page_links] ? windowed_links : []
    # previous/next buttons
    links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page pages', 
                    "#{@options[:previous_label]}",
                    "link prev go")
    links.push    page_link_or_span(@collection.next_page, 'disabled next_page pages',
                    #"#{@options[:next_label]}<img src='/images/next_pag.png' title='' alt='' />",
                    "#{@options[:next_label]}",
                    "link go")

    html = '<ul>' + links.join(@options[:separator]) + '</ul>'
    @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
  end

  protected

    def windowed_links
      visible_page_numbers.map { |n| page_link_or_span(n, (n == current_page ? 'selected' : nil)) }
    end

    def page_link_or_span(page, span_class, text = nil, inner_class = nil)
      text ||= page.to_s
      if page && page != current_page
        page_link(page, text, :class => span_class, :inner_class => inner_class)
      else
        page_span(page, text, :class => span_class, :inner_class => inner_class)
      end
    end

    def page_link(page, text, attributes = {})
      link_class = attributes[:inner_class]
      attributes.delete(:inner_class)
      @template.content_tag(:li, @template.link_to(text, url_for(page), :class => link_class), attributes)
    end

    def page_span(page, text, attributes = {})
      span_class = attributes[:inner_class]
      attributes.delete(:inner_class)
      @template.content_tag(:li, @template.content_tag(:span, text, :class => span_class), attributes)
    end
end
