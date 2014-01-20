require "opsworks/meta"
require "opsworks/config"
require "opsworks/commands/ssh"
require "opsworks/commands/describe"
require "opsworks/commands/custom_ami"
require "opsworks/commands/capistrano"
require "opsworks/commands/run_command"
require "opsworks/commands/create_instances"


class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end
end

module OpsWorks
end

def run_with_time(message, &blk)
  start = Time.now
  puts message + "..."
  yield
  puts "Done in #{(Time.now - start).round(2)} seconds."
end
