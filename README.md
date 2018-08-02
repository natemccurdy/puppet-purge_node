[![Puppet Forge](https://img.shields.io/puppetforge/v/nate/purge_node.svg)](https://forge.puppetlabs.com/nate/purge_node)
[![Build Status](https://travis-ci.org/natemccurdy/puppet-purge_node.svg?branch=master)](https://travis-ci.org/natemccurdy/puppet-purge_node)

# Purge Node Task

This module adds Tasks for purging nodes and cleaning certificates in Puppet.

For Puppet Enterprise users, this means you can allow users or admins to decommission nodes or clean certificates without giving them SSH access to your Puppet master! The ability to run this task remotely or via the Console is gated and tracked by the [RBAC system](https://puppet.com/docs/pe/2017.3/rbac/managing_access.html) built in to PE.

## Requirements

This module is compatible with Puppet Enterprise and Bolt.

* To [run tasks with Puppet Enterprise](https://puppet.com/docs/pe/2017.3/orchestrator/running_tasks.html), PE 2017.3 or later must be used.
* To [run tasks with Puppet Bolt](https://puppet.com/docs/bolt/0.x/running_tasks_and_plans_with_bolt.html), Bolt 0.5 or later must be installed on the machine from which you are running task commands. The master receiving the task must have SSH enabled.

## Tasks

Specify the agents that will be purged or cleaned using the `agent_certnames` parameter.

> Note: The target node of this task should always be your primary Puppet master (MoM or CA), not the agents being purged.

### `purge_node`

Use this task to completely purge Puppet agents from the environment.

This will completely remove the agent from the console, remove its reports, remove its certificate, and free up its PE license.

This task runs `puppet node purge <agent>` on your master.

Parameters:

* `agent_certnames`: The Puppet agents that will be purged. This can be one node or multiple nodes in a comma-separated list.

### `purge_node::clean_cert`

If you just want to remove a node's certificate without completely purging it, use the `purge_node::clean_cert` task.

This task runs `puppet cert clean <agent>` on your master.

Parameters:

* `agent_certnames`: The Puppet agents certificates that will be cleaned. This can be one node or multiple certs in a comma-separated list.

## Execute With Puppet Enterprise

With Puppet Enterprise 2017.3 or higher, you can run these tasks from the console ([see this link for documentation](https://puppet.com/docs/pe/2017.3/orchestrator/running_tasks_in_the_console.html)) or from the command line.

In this example, we are purging three agents from **master.corp.net**: `agent1`, `agent2`, and `agent3`

```shell
[nate@workstation]$ puppet task run purge_node agent_certnames=agent1,agent2,agent3 -n master.corp.net

Starting job ...
New job ID: 24
Nodes: 1

Started on master.corp.net ...
Finished on node master.corp.net
  agent2 :
    result : Node purged

  agent3 :
    result : Node purged

  agent1 :
    result : Node purged

Job completed. 1/1 nodes succeeded.
Duration: 6 sec
```

## Execute With Bolt

With [Bolt](https://puppet.com/docs/bolt/0.x/running_tasks_and_plans_with_bolt.html), you can run these tasks from the command line like so:

```shell
bolt task run purge_node agent_certnames=agent1,agent2,agent3 --nodes master.corp.net
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

