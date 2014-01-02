require 'aws-sdk'
require 'trollop'

require 'opsworks'

module OpsWorks::Commands
  class CustomAMI
    def self.banner
      "Create a custom AMI from an existing Opsworks layer"
    end

    def self.run
      options = Trollop::options do
        banner <<-EOS.unindent
          #{CustomAMI.banner}

          Options:
        EOS
        opt :stack, "Name of Opsworks stack", type: String
        opt :layer, "Name of Opsworks layer", type: String
        opt :instance_hostname, "Hostname of target instance", type: String
        opt :ami_name, "Name of the custom AMI", type: String
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
      puts layers.inspect
      layer = layers.detect {|l| l[:name] == options[:layer] }
      
      ec2_client = AWS::EC2.new(region: stack[:region])

      if options[:instance_hostname]
        
        run_with_time "Disabling auto-healing on #{options[:layer]} layer" do
          client.update_layer(layer_id: layer[:layer_id], enable_auto_healing: false)
        end
        
        instance = client.describe_instances(layer_id: layer[:layer_id]).data[:instances].detect {|instance| instance[:hostname] == options[:instance_hostname] }
        
        if instance[:status] == "stopped"

          puts "Instance is stopped already. Moving on to AMI creation step."

        else

          puts "Cleaning up instance #{options[:instance_hostname ]} via SSH."
          
          cleanup_commands = ['sudo /etc/init.d/monit stop',
                              'sudo /etc/init.d/opsworks-agent stop',
                              'sudo rm -rf /etc/aws/opsworks/ /opt/aws/opsworks/ /var/log/aws/opsworks/ /var/lib/aws/opsworks/
                              /etc/monit.d/opsworks-agent.monitrc /etc/monit/conf.d/opsworks-agent.monitrc /var/lib/cloud/']
          
          ssh_template = "ssh -i ~/.ec2/#{instance[:ssh_key_name]} ubuntu@#{options[:instance_hostname]} '%s'"
         
          cleanup_commands.each do |cmd|
            run_with_time "Running command: #{cmd}" do
              puts system(sprintf(ssh_template, cmd))
            end
          end

          client.stop_instance(instance_id: instance[:instance_id])

          run_with_time "Waiting for the instance to stop" do

            while client.describe_instances(layer_id: layer[:layer_id], instance_ids: [instance[:instance_id]]).data.first[:status] != "stopped"
              puts ".".chomp
              sleep 3
            end
          end
        end
       
        ami_name = "#{options[:ami_name]}_#{Time.now.strftime('%Y%m%d%H%M%S')}"

        run_with_time "Creating AMI #{ami_name} from instance #{options[:instance_hostname]}" do
          ec2_client.images.create(instance_id: instance[:ec2_instance_id], name: ami_name)
        end

        run_with_time "Enabling auto-healing on #{options[:layer]} layer" do
          client.update_layer(layer_id: layer[:layer_id], enable_auto_healing: true)
        end
      end
    end
  end
end
