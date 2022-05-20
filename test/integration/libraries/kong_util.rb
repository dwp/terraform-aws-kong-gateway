require 'net/http'
require 'uri'

def wait(url, max=500)
  count = 0
  while count <= max
    begin
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      raise "Bad response from kong gateway: #{response.code}" if response.code.to_i != 200

      raise 'empty cluster body' if JSON.parse(response.body).empty?

      break
    rescue Exception => e
      count += 1
      if count == max
        raise 'There was an issue with contacting the Kong control plane, check if the Kong service is running'
      end

      sleep 1
      next
    end
  end
end

def post(url, data)
  uri = URI.parse(url)
  request = Net::HTTP::Post.new(uri)
  request.set_form_data(data)
  Net::HTTP.start(uri.hostname, uri.port).request(request)
end
