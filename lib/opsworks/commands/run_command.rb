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
        opt :hostname, "Desired instance hostname", type: String
      end

      %w(stack layer instance_hostname ami_name).each do |a|
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
      
      ec2_client = AWS::EC2.new(region: stack[:region])

      create_options = {stack: stack[:stack_id], layer_ids: [layer[:layer_id]]}
      
      create_options[:auto_scaling_type] = options[:auto_scaling_type] || nil

      if options[:ami_id]
        create_options[:ami_id] = options[:ami_id]
        create_options[:os] = "Custom"
      else
        create_options[:os] = "Ubuntu 12.04 LTS"
      end

      client.create_instance(create_options)        
       
    end
  end
end
