[![Puppet Forge](https://img.shields.io/puppetforge/v/nate/purge_node.svg)](https://forge.puppetlabs.com/nate/purge_node)
[![Build Status](https://travis-ci.org/natemccurdy/puppet-purge_node.svg?branch=master)](https://travis-ci.org/natemccurdy/puppet-purge_node)

# The Purge Node Task

This module provides Puppet Bolt tasks for purging Puppet agents and cleaning their certificates.

For open-source Puppet Bolt users, this allows for cleaning agent certificates using Bolt and the SSH transport.

For Puppet Enterprise (PE) users, this allows for cleaning and purging agents with the SSH transport or the PE Orchestrator's PCP transport. PE's [RBAC system](https://puppet.com/docs/pe/2019.2/managing_access.html) can gate access to running these tasks via the PE Console or with Puppet Tasks through the Orchestrator API.

## Requirements

For open-source Bolt users:
* Bolt 0.5+ is required
* SSH is the only transport available

For Puppet Enterprise users:
* PE 2017.3+ is required
* The SSH or PCP (Orchestrator) transports can be used


## Task: `purge_node`

> NOTE:
>  * This task only works with Puppet Enterprise.
>  * The target of this task must be your primary Puppet Enterprise master---not the agent(s) being purged.

The __purge_node__ task is used to run the [`puppet node purge` command](https://puppet.com/docs/pe/2019.2/adding_and_removing_nodes.html#remove-nodes) command against a list of specified Puppet agent(s). This has the effect of completely removing an agent from your PE infrastructure. Its reports are removed, its certificate is cleaned, and its license is freed up.

Parameters:

* `agent_certnames`: The Puppet agents that will be purged. This can be one certname or multiple certnames in a comma-separated list or JSON array.

Examples:

```
$ puppet task run purge_node agent_certnames=agent1,agent2,agent3 --nodes puppet-ca.corp.net
```

## Task: `purge_node::clean_cert`

> NOTE:
>  * This task works with open-source Puppet(server) and Puppet Enterprise.
>  * The target of this task must be your primary Puppet master---not the agent(s) being cleaned.

The __purge_node::clean_cert__ task is used to clean a Puppet agent's certificate. For Puppetserver >= 6.0, `puppetserver ca clean` is used. For Puppetserver < 6.0, `puppet cert clean` is used.

Parameters:

* `agent_certnames`: The agent certificate names that will be cleaned. This can be one certname or multiple certnames in a comma-separated list or JSON array.

Examples:

```
$ bolt task run purge_node::clean_cert agent_certnames=agent1,agent2,agent3 --targets puppet-ca.corp.net
```

## Running the Tasks

### With Bolt

With Bolt, you can run these tasks tasks [from the command line](https://puppet.com/docs/bolt/latest/bolt_running_tasks.html) with `bolt task run`.

To purge a node (PE only):
```shell
$ bolt task run purge_node agent_certnames=agent1,agent2,agent3 --nodes master.corp.net
```

To clean a node's certifiate:
```shell
$ bolt task run purge_node::clean_cert agent_certnames=agent1,agent2,agent3 --nodes master.corp.net
```

### With Puppet Enterprise

With Puppet Enterprise 2017.3 or higher, you can run these tasks [from_the_console](https://puppet.com/docs/pe/2019.2/running_tasks_in_the_console.html#running-tasks-console), [from the command line](https://puppet.com/docs/pe/2019.2/running_tasks_from_the_command_line.html#running-tasks-cli), or [from the Orchestrator API](https://puppet.com/docs/pe/2019.2/orchestrator_api_v1_endpoints.html).

In this example, three agents are purged from *master.corp.net*: `agent1`, `agent2`, and `agent3`

```shell
[nate@workstation]$ puppet task run purge_node agent_certnames=agent1,agent2,agent3 --nodes master.corp.net

[nate@workstation ~]# puppet task run purge_node agent_certnames=agent1,agent2,agent3 --nodes master.corp.net
Starting job ...
Note: The task will run only on permitted nodes.
New job ID: 5
Nodes: 1

Started on master.corp.net ...
Finished on node master.corp.net
  agent1 :
    result : Node purged

  agent2 :
    result : Node purged

  agent3 :
    result : Node purged
|
Job completed. 1/1 nodes succeeded.
Duration: 17 sec
```

In addition to the comma-separated list of certnames, the `agent_certnames` parameter can accept JSON array as input. This is useful when using the Orchestrator API to run tasks. The example below is a valid request to [the commands endpoint](https://puppet.com/docs/pe/2019.2/orchestrator_api_commands_endpoint.html#orchestrator_api_commands_endpoint).

```json
{
  "environment" : "production",
  "task" : "purge_node",
  "params" : {
    "agent_certnames" : ["agent1", "agent2", "agent3"]
  },
  "scope" : {
    "nodes" : ["master.corp.net"]
  }
}
```

## Finishing the Job

If you are on Puppet Enterprise 2017.3 or higher and you only have one Puppet master, you're done. There's nothing else you need to do after running this task.

For everyone else, continue reading...

### Puppetserver Reload

On Puppetserver versions [before](https://puppet.com/docs/puppetserver/5.1/release_notes.html#new-feature-automatic-crl-refresh-on-certificate-revocation) [5.1.0](https://tickets.puppetlabs.com/browse/SERVER-1933), the `puppetserver` process needs to be reloaded/restarted to re-read the certificate revocation list (CRL) after purging a node. **If you are at or above this version, you don't need to restart the `puppetserver` process**.

This task does **not** restart `puppetserver` for you. It may in future versions.

### Compile Masters

If you have Puppet Enterprise with a Master-of-Masters (MoM) and Compile Masters, you don't need to restart puppetserver but you do need to trigger a puppet run on the Compile Masters after purging to completely refresh the CRL and prevent that node from checking in again.

This can be done with the Orchestrator via the Console's Jobs page or the command line, like so:

```shell
puppet job run -q 'resources { type = "Class" and title = "Puppet_enterprise::Profile::Master" and !(certname = "FQDN_of_your_MoM") }'
```

## Development

This module uses the [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/1.x/pdk.html) to manage unit tests and style validation.

If you're going to submit a change, please consider using the PDK to validate your change:

1. Install the PDK
    * (MacOS) `brew cask install puppetlabs/puppet/pdk`
1. Run validation tests: `pdk validate`

