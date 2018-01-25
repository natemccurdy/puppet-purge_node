[![Puppet Forge](https://img.shields.io/puppetforge/v/nate/purge_node.svg)](https://forge.puppetlabs.com/nate/purge_node)

# Purge Node Task

This module adds a Task for purging Puppet agents.

## Example Usage

### Puppet Enterprise Tasks

With Puppet Enterprise 2017.3 or higher, you can run this task with `puppet task` from the command line. For example, to purge the `foo`, `bar`, and `baz` nodes from the Puppet master, `master.corp.net`:

```shell
[nate@workstation]$ puppet task run purge_node agent_certnames=foo,bar,baz -n master.corp.net

Starting job ...
New job ID: 24
Nodes: 1

Started on master.corp.net ...
Finished on node master.corp.net
  bar :
    result : Node purged

  baz :
    result : Node purged

  foo :
    result : Node purged

Job completed. 1/1 nodes succeeded.
Duration: 6 sec
```

### Bolt

With [Bolt](https://puppet.com/docs/bolt/0.x/running_tasks_and_plans_with_bolt.html), you can run this task on the command line like so:

```shell
bolt task run purge_node agent_certnames=foo,bar,baz --nodes master.corp.net
```

## Parameters

* `agent_certnames`: A comma-separated list of Puppet agent certificate names.

## Finishing the Job

If you are on Puppet Enterprise 2017.2.4 or higher and you only have one Puppet master, you're done. There's nothing else you need to do after running this task.

For everyone else, continue reading...

### Puppetserver Reload

On versions of Puppet Enterprise before [2017.2.4](https://puppet.com/docs/pe/2017.2/release_notes.html#purge-nodes-without-a-restart) and Puppetserver versions [before](https://puppet.com/docs/puppetserver/5.1/release_notes.html#new-feature-automatic-crl-refresh-on-certificate-revocation) [5.1.0](https://tickets.puppetlabs.com/browse/SERVER-1933), the `puppetserver` process needs to be reloaded/restarted to re-read the certificate revocation list (CRL) after purging a node. **If you are at or above those versions, you don't need to restart the `puppetserver` process**.

This task does **not** restart `puppetserver` for you. It may in future versions.

### Compile Masters

If you have Puppet Enterprise with a Master-of-Masters (MoM) and Compile Masters and you have version 2017.2.4 or higher, you don't need to restart puppetserver but you do need to trigger a puppet run on the Compile Masters after purging to completely refresh the CRL and prevent that node from checking in again.

This can be done with the Orchestrator via the Console's Jobs page or the command line, like so:

```shell
puppet job run -q 'resources { type = "Class" and title = "Puppet_enterprise::Profile::Master" and !(certname = "FQDN_of_your_MoM") }'
```

