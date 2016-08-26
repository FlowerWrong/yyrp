require 'ruby-progressbar'
require 'net/http'
require 'uri'

def down(url, save_file_path)
  uri = URI.parse(url)
  @counter = 0
  @pbar = nil

  Net::HTTP.start(uri.host, uri.port) do |http|
    response = http.request_head(uri.path)
    file_size = response['content-length'].to_i
    @pbar = ProgressBar.create(format: '%a |%b>>%i| %p%% %t', starting_at: 0)
    @pbar.total = file_size
    File.open(save_file_path, 'w') {|f|
      http.get(uri.path) do |str|
        f.write str
        @counter += str.length
        @pbar.progress = @counter
      end
    }
  end
  @pbar.finish
  puts 'Down Done'
end