api = input('kong-api-endpoint')
proxy = input('kong-proxy-endpoint')
portal = input('kong-portal-endpoint')
region = attribute('aws_region')
token_path = input('admin_token_path')

require_relative '../../libraries/kong_util'

token = aws_get_parameter(token_path, region)

wait("#{api}/clustering/status", token) # wait for Kong to be running

control 'Apply Kong license' do
    impact 1
    title 'Apply Kong licence'
    post("#{api}/licenses", { 'payload' => ENV['KONG_EE_LICENSE'] }, token)
end

control 'Create service and route' do
    impact 1
    title 'Creating service and route should succeed'
    describe http("#{api}/services/test", method: 'PUT', headers: {'kong-admin-token' => token}, data: { 'name' => 'test', 'url' => 'http://httpbin.org' }) do
      its('status') { should be_in [ 200, 201 ] }
    end
    describe http("#{api}/services/test/routes/testRoute", headers: {'kong-admin-token' => token}, method: 'PUT', data: { 'name' => 'testRoute', 'paths' => '/test' }) do
      its('status') { should be_in [ 200, 201 ] }
    end
end

control 'Cluster Size' do
  impact 1
  title 'Cluster should not be empty'
  describe http("#{api}/clustering/status", headers: {'kong-admin-token' => token}) do
    its('body') { should_not be_empty }
    its('status') { should cmp 200 }
  end
end

control 'Test Service' do
  impact 0.7
  title 'Service should be available'

  describe http("#{api}/services/test", headers: {'kong-admin-token' => token}) do
    its('status') { should cmp 200 }
  end
end

control 'Test route' do
  impact 1
  title 'The test route should be working'

  post("#{api}/services", { 'name' => 'httpbin', 'url' => 'http://httpbin.org' }, token)
  post("#{api}/services/httpbin/routes", { 'name' => 'httpbin', 'paths' => '/httpbin' }, token)
  sleep(10) # wait for route to propagate

  describe http("#{api}/services/httpbin/routes/httpbin", headers: {'kong-admin-token' => token}) do
    its('status') { should cmp 200 }
  end
  describe http("#{proxy}/httpbin/get", headers: {'kong-admin-token' => token}) do
    its('status') { should cmp 200 }
  end
end

control 'Portal' do
  impact 1
  title 'The portal workspace should be created and the portal enabled'

  post("#{api}/workspaces", {"name" => "portal"}, token)
  patch("#{api}/workspaces/portal", {"config.portal" => "true"}, token)

  describe http("#{portal}/portal") do
    its('status') { should cmp 200 }
  end
end
