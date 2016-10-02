class Response
  attr_accessor :all_data, :headers, :body, :http_version, :response_line
  def initialize(headers = {})
    @headers = headers
    @all_data = []
  end
end
