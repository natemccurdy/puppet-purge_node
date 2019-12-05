#!/opt/puppetlabs/puppet/bin/ruby
#
# Puppet Task to purge nodes
# This can only be run against a Puppet Enterprise CA master.
#
# Parameters:
#   * agent_certnames - A comma-separated list of agent certificate names.
#
require 'puppet'
require 'open3'
require 'json'

Puppet.initialize_settings

def targetting_a_ca?
  # This task only works when running against your Puppet CA server, so let's check for that.
  # In Puppet Enterprise, that means that the bootstrap.cfg file contains 'certificate-authority-service'.
  bootstrap_cfg = '/etc/puppetlabs/puppetserver/bootstrap.cfg'

  File.exist?(bootstrap_cfg) && !File.readlines(bootstrap_cfg).grep(%r{^[^#].+certificate-authority-service$}).empty?
end

def purge_node(agent)
  stdout, stderr, status = Open3.capture3('/opt/puppetlabs/puppet/bin/puppet', 'node', 'purge', agent)
  {
    stdout: stdout.strip,
    stderr: stderr.strip,
    exit_code: status.exitstatus,
  }
end

results = {}
exitcode = 0

if !targetting_a_ca?

  results[:_error] = {
    msg: 'Error: This task does not appear to be targetting a Puppet Enterprise CA master. Refusing to continue.',
  }
  exitcode = 1

else

  params = JSON.parse(STDIN.read)
  agents = params['agent_certnames'].is_a?(Array) ? params['agent_certnames'] : params['agent_certnames'].split(',')

  agents.each do |agent|
    results[agent] = {}

    if agent == Puppet[:certname]
      results[agent][:result] = 'Refusing to purge the Puppet Master'
      next
    end

    output = purge_node(agent)
    results[agent][:result] = output[:exit_code].zero? ? 'Node purged' : output
  end
end

puts results.to_json
exit exitcode
