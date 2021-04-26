api = input('kong-api-endpoint')
proxy = input('kong-proxy-endpoint')

require_relative '../../libraries/kong_util'

wait("#{api}/clustering/status")

post("#{api}/services", { 'name' => 'test', 'url' => 'http://httpbin.org' })

post("#{api}/services/test/routes", { 'name' => 'testRoute', 'paths' => '/test' })

cluster_members = JSON.parse(http("#{api}/clustering/status", method: 'GET').body)

describe cluster_members do
  it { should_not be_empty }
end

describe http("#{api}/services/test",
              method: 'GET') do
                its('status') { should cmp 200 }
              end

describe http("#{api}/services/test/routes/testRoute",
              method: 'GET') do
                its('status') { should cmp 200 }
              end

sleep(10) # wait for route to propergate
describe http("#{proxy}/test/get",
              method: 'GET') do
                its('status') { should cmp 200 }
              end
