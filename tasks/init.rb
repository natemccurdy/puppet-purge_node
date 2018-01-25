#!/opt/puppetlabs/puppet/bin/ruby
#
# Puppet Task to purge nodes
# This can only be run against the Puppet Master.
#
# Parameters:
#   * agent_certnames - A comma-separated list of agent certificate names.
#
require 'puppet'
require 'open3'

Puppet.initialize_settings

unless Puppet[:server] == Puppet[:certname]
  puts 'This task can only be run against the Master (of Masters)'
  exit 1
end

def purge_node(agent)
  command = "/opt/puppetlabs/puppet/bin/puppet node purge #{agent}"

  stdout, stderr, status = Open3.capture3(command)
  {
    stdout: stdout.strip,
    stderr: stderr.strip,
    exit_code: status.exitstatus,
  }
end

agents = ENV['PT_agent_certnames'].split(',')

result = {}

agents.each do |agent|
  result[agent] = {}

  if agent == Puppet[:certname]
    result[agent][:result] = 'Refusing to purge the Puppet Master'
    next
  end

  output = purge_node(agent)
  result[agent][:result] = if output[:exit_code].zero?
                             'Node purged'
                           else
                             output
                           end
end

puts result.to_json
