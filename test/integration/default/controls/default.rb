require 'net/http'
require 'uri'

api = input('kong-api-endpoint')
manager = input('kong-manager-endpoint')
proxy = input('kong-proxy-endpoint')
token = input('kong-super-admin-token')

# set up service and route so we can test
uri = URI.parse("#{api}/services")
request = Net::HTTP::Post.new(uri)
request['Kong-Admin-Token'] = token
request.set_form_data(
  'name' => 'test',
  'url' => 'http://httpbin.org'
)

Net::HTTP.start(uri.hostname, uri.port).request(request)

uri = URI.parse("#{api}/services/test/routes")
request = Net::HTTP::Post.new(uri)
request['Kong-Admin-Token'] = token
request.set_form_data(
  'name' => 'testRoute',
  'paths' => '/test'
)

Net::HTTP.start(uri.hostname, uri.port).request(request)

# start testing
cluster_members = JSON.parse(http("#{api}/clustering/status",
                                  method: 'GET',
                                  headers: { 'Kong-Admin-Token' => token }).body)
describe cluster_members do
  it { should_not be_empty }
end

describe http("#{api}/services/test",
              method: 'GET',
              headers: { 'Kong-Admin-Token' => token }) do
                its('status') { should cmp 200 }
              end

describe http("#{api}/services/test/routes/testRoute",
              method: 'GET',
              headers: { 'Kong-Admin-Token' => token }) do
                its('status') { should cmp 200 }
              end

sleep(10) # wait for route to propergate
describe http("#{proxy}/test/get",
              method: 'GET',
              headers: { 'Kong-Admin-Token' => token }) do
                its('status') { should cmp 200 }
              end

describe http(manager, method: 'GET') do
  its('status') { should cmp 200 }
end
