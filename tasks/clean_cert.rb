#!/opt/puppetlabs/puppet/bin/ruby
#
# Puppet Task to clean a node's certificate
# This can only be run against the Puppet Master.
#
# Parameters:
#   * agent_certnames - A comma-separated list of agent certificates to clean/remove.
#
require 'puppet'
require 'open3'

Puppet.initialize_settings

unless Puppet[:server] == Puppet[:certname]
  puts 'This task can only be run on the Master (of Masters)'
  exit 1
end

def clean_cert(agent)
  stdout, stderr, status = Open3.capture3('/opt/puppetlabs/puppet/bin/puppet', 'cert', 'clean', agent)
  {
    stdout: stdout.strip,
    stderr: stderr.strip,
    exit_code: status.exitstatus,
  }
end

results = {}
agents = ENV['PT_agent_certnames'].split(',')

agents.each do |agent|
  results[agent] = {}

  if agent == Puppet[:certname]
    results[agent][:result] = 'Refusing to remove the Puppet Master certificate'
    next
  end

  output = clean_cert(agent)
  results[agent][:result] = if output[:exit_code].zero?
                              'Certificate removed'
                            else
                              output
                            end
end

puts results.to_json
