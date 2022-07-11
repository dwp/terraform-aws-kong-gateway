api = input('kong-api-endpoint')
proxy = input('kong-proxy-endpoint')

require_relative '../../libraries/kong_util'

wait("#{api}/clustering/status") # wait for Kong to be running

control 'Create service and route' do
  impact 1
  title 'Creating service and route should succeed'
  describe http("#{api}/services/test", method: 'PUT', data: { 'name' => 'test', 'url' => 'http://httpbin.org' }) do
    its('status') { should be_in [ 200, 201 ] }
  end
  describe http("#{api}/services/test/routes/testRoute", method: 'PUT', data: { 'name' => 'testRoute', 'paths' => '/test' }) do
    its('status') { should be_in [ 200, 201 ] }
  end
end

control 'Cluster Size' do
  impact 1
  title 'Cluster should not be empty'
  describe http("#{api}/clustering/status") do
    its('body') { should_not be_empty }
    its('status') { should cmp 200 }
  end
end

control 'Test Service' do
  impact 0.7
  title 'Service should be available'

  describe http("#{api}/services/test") do
    its('status') { should cmp 200 }
  end
end

control 'Test route' do
  impact 1
  title 'The test route should be working'

  post("#{api}/services", { 'name' => 'httpbin', 'url' => 'http://httpbin.org' })
  post("#{api}/services/httpbin/routes", { 'name' => 'httpbin', 'paths' => '/httpbin' })
  sleep(10) # wait for route to propagate

  describe http("#{api}/services/httpbin/routes/httpbin") do
    its('status') { should cmp 200 }
  end
  describe http("#{proxy}/httpbin/get") do
    its('status') { should cmp 200 }
  end
end
