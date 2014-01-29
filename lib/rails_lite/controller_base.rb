require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res, :already_rendered

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @route_params = route_params
    @already_rendered = false
    #@session = nil
    #@params = Params.new(req, route_params)
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    if already_rendered?
      raise "Double render"
    else
      @res.body = content
      @res.content_type = type
      @already_rendered = true
      session.store_session(@res)
    end
  end

  # helper method to alias @already_rendered
  def already_rendered?
    @already_rendered
  end

  # set the response status code and header
  def redirect_to(url)
    if already_rendered?
      raise "Double render"
    else
      @res.header["location"] = url
      @res.status = 302
      @already_rendered = true
      session.store_session(@res)
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    template_erb =ERB.new(File.read("views/#{self.class.to_s.underscore}/#{template_name}.html.erb"))

    render_content(template_erb.result(binding), "text/html")
    session.store_session(@res)
  end
    #
    # template_fname =
    #   File.join("views", self.class.name.underscore, "#{template_name}.html.erb")
    # render_content(
    #   ERB.new(File.read(template_fname)).result(binding),
    #   "text/html"



  # method exposing a `Session` object
  def session
    @session ||= Session.new(@res)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end
end
