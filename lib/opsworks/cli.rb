require 'trollop'
require 'opsworks'

class OpsWorks::CLI
  def self.start
    commands = %w(ssh describe custom_ami capistrano play)

    Trollop::options do
      version "opsworks #{OpsWorks::VERSION} " <<
              "(c) #{OpsWorks::AUTHORS.join(", ")}"
      banner <<-EOS.unindent
        usage: opsworks [COMMAND] [OPTIONS...]

        #{OpsWorks::SUMMARY}

        Commands
          ssh        #{OpsWorks::Commands::SSH.banner}
          describe   #{OpsWorks::Commands::Describe.banner}
          custom_ami #{OpsWorks::Commands::CustomAMI.banner}
          capistrano #{OpsWorks::Commands::Capistrano.banner}
          play       Play with the Opsworks client in a console
        For help with specific commands, run:
          opsworks COMMAND -h/--help

        Options:
      EOS
      stop_on commands
    end

    command = ARGV.shift
    case command
      when "ssh"
        OpsWorks::Commands::SSH.run
      when "describe"
        OpsWorks::Commands::Describe.run
      when "custom_ami"
        OpsWorks::Commands::CustomAMI.run
      when "capistrano"
        OpsWorks::Commands::Capistrano.run
      when "play"
        require 'pry'
        config = OpsWorks.config
        client = AWS::OpsWorks::Client.new
        binding.pry
      when nil
        Trollop::die "no command specified"
      else
        Trollop::die "unknown command: #{command}"
    end

  end
end