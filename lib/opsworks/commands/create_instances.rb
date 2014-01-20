require 'aws-sdk'
require 'trollop'

require 'opsworks'

module OpsWorks::Commands
  class CreateInstances
    def self.banner
      "Create an Opsworks instance"
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
        opt :ami_name, "Name of custom AMI source", type: String
        opt :instance_type, "EC2 instance type", type: String
        opt :availability_zone, "Instance availability zone. If left out, one will fewer assigned instances will be chosen randomly.", type: String
        opt :auto_scaling_type, "Auto scaling type, valid options: load, timer. 'always on' is the default.", type: String
      end

      %w(stack layer hostname ami_name instance_type).each do |a|
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
      create_options = {stack_id: stack[:stack_id],
                        hostname: options[:hostname],
                        layer_ids: [layer[:layer_id]],
                        availability_zone: options[:availability_zone],
                        instance_type: options[:instance_type]
                       }
      
      create_options[:auto_scaling_type] = options[:auto_scaling_type] if options[:auto_scaling_type]

      if options[:ami_id]
        create_options[:ami_id] = options[:ami_id]
        create_options[:os] = "Custom"
      else
        create_options[:os] = "Ubuntu 12.04 LTS"
      end

      result = client.create_instance(create_options)
      puts "Created instance with id #{result.data[:instance_id]}"
       
    end
  end
end
