require 'aws-sdk'
require 'trollop'

require 'opsworks'

PREFIX  = "# --- OpsWorks ---"
POSTFIX = "# --- End of OpsWorks ---"

module OpsWorks::Commands
  class Capistrano
    def self.banner
      "Update or create a capistrano file containing a stack's target hosts for deployment"
    end

    def self.run
      options = Trollop::options do
        banner <<-EOS.unindent
          #{SSH.banner}

          Options:
        EOS

        opt :stack, "Opsworks stack name", type: String        
        opt :layer, "Opsworks layer name", type: String
        opt :backup, "Backup old file config before updating", default: false
        opt :role_name, "Name of your capistrano role. Default: app", type: String
        opt :file, "Path of capistrano role file. Default: ./config/deploy/opsworks.rb", type: String
      end


      %w(stack layer).each do |a|
        if !options[a.to_sym]
          Trollop.die(a.to_sym, "#{a} is required")
        end
      end

      config = OpsWorks.config

      client = AWS::OpsWorks::Client.new

      options[:variable_name] ||= "app"
      instances = []

      stacks = client.describe_stacks.data[:stacks]
      stack = stacks.detect {|s| options[:stack] == s[:name] }

      layers = client.describe_layers(stack_id: stack[:stack_id]).data[:layers].detect {|l| l[:name] == options[:layer]}

      result = client.describe_instances(stack_id: stack[:stack_id])
      instances += result.instances.select { |i| i[:status] != "stopped" }
      
      instances.reject! { |i| i[:elastic_ip].nil? && i[:public_ip].nil? }
      instances.collect! {|i| i[:elastic_ip] || i[:public_ip] }

      new_contents = "#{PREFIX}\n" <<
                     "set :#{options[:variable_name]}, #{instances.to_s}\n" <<
                     "#{POSTFIX}\n\n"

      path = options[:file] || "./config/deploy/opsworks.rb"

      old_contents = File.exists?(path) ?  File.read(path) : ""

      if options[:backup]

        base_name = path + ".backup"

        if File.exists? base_name
          number = 0
          file_name = "#{base_name}-#{number}"
          while File.exists? file_name
            file_name = "#{base_name}-#{number += 1}"
          end
        else
          file_name = base_name
        end

        File.open(file_name, "w") { |file| file.puts old_contents }
      end

      File.open(path, "w") do |file|
        file.puts new_contents

        file.puts old_contents.gsub(
          /\n?\n?#{PREFIX}.*#{POSTFIX}\n?\n?/m,
          ''
        )
      end

      puts "Successfully updated #{path} with " <<
           "#{instances.length} instances!"
    end
  end
end
