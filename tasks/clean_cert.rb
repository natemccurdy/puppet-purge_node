#!/opt/puppetlabs/puppet/bin/ruby
#
# Puppet Task to clean a node's certificate
# This can only be run against a Puppet Master.
#
# Parameters:
#   * agent_certnames - A comma-separated list of agent certificates to clean/remove.
#
require 'puppet'
require 'open3'

Puppet.initialize_settings

def targetting_a_ca?
  # This task only works when running against your Puppet CA server, so let's check for that.
  # In Puppet Enterprise, that means that the bootstrap.cfg file contains 'certificate-authority-service'.
  bootstrap_cfg = '/etc/puppetlabs/puppetserver/bootstrap.cfg'

  File.exist?(bootstrap_cfg) && !File.readlines(bootstrap_cfg).grep(%r{^[^#].+certificate-authority-service$}).empty?
end

def clean_cmd
  # Puppetserver 6 uses the new 'ca' commands.
  if Puppet::Util::Package.versioncmp(Puppet.version, '6.0.0') >= 0
    ['/opt/puppetlabs/bin/puppetserver', 'ca', 'clean', '--certname']
  else
    ['/opt/puppetlabs/puppet/bin/puppet', 'cert', 'clean']
  end
end

def clean_cert(agent)
  stdout, stderr, status = Open3.capture3(*[clean_cmd, agent].flatten)
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
    msg: 'Error: This task does not appear to be targetting a Puppet CA master. Refusing to continue.',
  }
  exitcode = 1

else

  agents = ENV['PT_agent_certnames'].split(',')

  agents.each do |agent|
    results[agent] = {}

    if agent == Puppet[:certname]
      results[agent][:result] = "Error: Refusing to remove the Puppet Master's certificate"
      exitcode = 2
      next
    end

    output = clean_cert(agent)
    results[agent][:result] = if output[:exit_code].zero?
                                'Certificate removed'
                              else
                                output
                              end
  end
end

puts results.to_json
exit exitcode
