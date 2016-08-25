class Response
  attr_accessor :headers, :body, :http_version, :response_line
  def initialize(headers = {})
    @headers = headers
  end
end