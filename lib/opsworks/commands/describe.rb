require 'aws-sdk'
require 'trollop'

require 'opsworks'

module OpsWorks::Commands
  class Describe
    def self.banner
      "Show a concise overview of an Opsworks environment"
    end

    def self.run
      options = Trollop::options do
        banner <<-EOS.unindent
          #{Describe.banner}

          Options:
        EOS
        opt :json, "Print the stack's custom Chef JSON", default: false
      end

      config = OpsWorks.config

      client = AWS::OpsWorks::Client.new

      client.describe_stacks.data[:stacks].each do |stack|
        stack_title = "#{stack[:name]} (#{stack[:stack_id]}): #{stack[:region]}, #{stack[:default_root_device_type]}"
        puts
        puts stack_title
        puts "-"*stack_title.length 

        if options[:json]
          puts stack[:custom_json]
        end

        client.describe_layers(stack_id: stack[:stack_id]).data[:layers].each do |layer|
          puts
          puts layer[:name]
          puts "-"*layer[:name].length

          client.describe_instances(layer_id: layer[:layer_id]).data[:instances].each do |instance|
            puts "  #{instance[:hostname]} (#{instance[:ec2_instance_id]}) #{instance[:availability_zone]} #{instance[:private_ip]}/#{instance[:public_ip]}: #{instance[:status]}"
          end
        end
      end
      
      puts 
    end
  end
end
