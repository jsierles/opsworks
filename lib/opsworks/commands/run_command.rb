require 'aws-sdk'
require 'trollop'

require 'opsworks'

module OpsWorks::Commands
  class RunCommand
    def self.banner
      "Run an Opsworks"
    end

    def self.run
      options = Trollop::options do
        banner <<-EOS.unindent
          #{CreateInstances.banner}

          Options:
        EOS
        opt :stack, "Name of Opsworks stack", type: String
        opt :layer, "Name of Opsworks layer", type: String
        opt :command, "Command to run: setup, configure, execute_recipes, update_custom_cookbooks, update_dependencies", type: String
      end


      %w(stack layer command).each do |a|
        if !options[a.to_sym]
          Trollop.die(a.to_sym, "#{a} is required")
        end
      end
     
      config = OpsWorks.config

      client = AWS::OpsWorks::Client.new
      
      stacks = client.describe_stacks.data[:stacks]

      stack = stacks.detect {|s| options[:stack] == s[:name] }
      layers = client.describe_layers(stack_id: stack[:stack_id]).data[:layers]      
      layer = layers.detect {|l| l[:name] == options[:layer] }

      command = {name: options[:command]}

      puts "Running #{options[:command]}..."

      client.create_deployment(stack_id: stack[:stack_id], command: command)

      puts "Done!"       
    end
  end
end
