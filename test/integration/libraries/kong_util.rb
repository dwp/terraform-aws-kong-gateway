require 'net/http'
require 'uri'
require 'aws-sdk-ssm'

def wait(url, type="control_plane", token=nil, max=500)
  count = 0
  while count <= max
    begin
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      request['Kong-Admin-Token'] = token
      response = Net::HTTP.start(uri.hostname, uri.port).request(request)
      raise "Bad response from Kong: #{response.code}" if response.code.to_i != 200

      if type == "control_plane"
        raise 'empty cluster body' if JSON.parse(response.body).empty?
      end

      break
    rescue Exception => e
      count += 1
      if count == max
        raise 'There was an issue with contacting Kong, check if the Kong service is running'
      end

      sleep 1
      next
    end
  end
end

def post(url, data, token=nil)
  uri = URI.parse(url)
  request = Net::HTTP::Post.new(uri)
  request.set_form_data(data)
  request['Kong-Admin-Token'] = token
  Net::HTTP.start(uri.hostname, uri.port).request(request)
end

def patch(url, data, token=nil)
  uri = URI.parse(url)
  request = Net::HTTP::Patch.new(uri)
  request.set_form_data(data)
  request['Kong-Admin-Token'] = token
  Net::HTTP.start(uri.hostname, uri.port).request(request)
end

def aws_get_parameter(path, region)
  ssm_client = Aws::SSM::Client.new(region: region)
  response = ssm_client.get_parameter({
      name: path,
      with_decryption: true,
  })
  return response.parameter.value
end
