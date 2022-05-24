api = input('kong-api-endpoint')
proxy = input('kong-proxy-endpoint')

require_relative '../../libraries/kong_util'

wait("#{api}/clustering/status")

describe http("#{api}/services/test", method: 'POST') do
  its('status') { should cmp 200 }
end

control 'Cluster Size' do
  impact 1
  title 'Cluster should not be empty'
  describe http("#{api}/clustering/status") do
    its('body') { should_not be_empty }
    its('status') { should cmp 200 }
  end
end

control 'Test Services' do
  impact 0.7
  title 'Services should be available'

  describe http("#{api}/services/test") do
    its('status') { should cmp 200 }
  end
end

# sleep(10) # wait for route to propagate

control 'Working route' do
  impact 1
  title 'The test route should be working'

  describe http("#{api}/services/test/routes/testRoute") do
    its('status') { should cmp 200 }
  end

  describe http("#{proxy}/test/get") do
    its('status') { should cmp 200 }
  end
end
