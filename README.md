# OpsWorks CLI

Command line interface for Amazon OpsWorks.

## Commands

Run `opsworks` with one of the following commands:

* `ssh` Generate and update SSH configuration files.

   Instances are added in stack order to the SSH configuration. If you have
   instances with the same name in multiple stacks, the one from the first
   stack will be used by SSH.

* `describe` Describe your stack(s).

   This prints your stack info, including latest 5 deployments and state of
   the layers/instances. Useful to see how deployments are going.

* `capistrano` Create a capistrano configuration for a specific layer

   If you deploy via capistrano, this helps you generate your server array in a config file.

*  `custom_ami` Build a custom AMI based on an existing Opsworks instance.

  This is a *work in progress*. It runs commands for cleaning up the instance for packaging,
  then hits EC2 to do the AMI packaging work.

*  `run_command' Run deployment commands, for deploying apps, updating recipes or managing lifecycle events

  Run commands like: setup, configure, update_custom_cookbooks, update_dependencies
  Execute_recipes is not supported yet.

*  `update_stack` Update a stack's custom JSON

  Update the stack's custom JSON from a file. No other attributes are updatable yet!

## Configuration

This gem uses the same configuration file as the [AWS CLI][aws_cli]. This
requires you to have a working AWS CLI setup before continuing.

Add the following section to `~/.aws/config` or to the file pointed out by the
`AWS_CONFIG_FILE` environment variable:

    [opsworks]
    stack-id=<MY STACK IDs>
    ssh-user-name=<MY SSH USER NAME>

The stack ID is optional for most commands, as they accept a command line option.

The stack ID can be found in the stack settings, under _OpsWorks ID_ (or in the
address bar of your browser as
`console.aws.amazon.com/opsworks/home?#/stack/<STACK_ID>/stack`). You can add
several stack IDs belonging to the same IAM account separated by commas
(`stack-id=STACK1,...,STACKN`).

The `ssh-user-name` value should be set to the username you want to use when
logging in remotely, most probably the user name from your _My Settings_ page
on OpsWorks.

## Installation

Install for use on the command line (requires Ruby and Rubygems):

    $ gem install opsworks

Then run `opsworks`:

    $ opsworks --help

To use the gem in a project, add this to your `Gemfile`:

    gem 'opsworks'

And then execute:

    $ bundle

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[aws_cli]: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html "Amazon AWS CLI"
