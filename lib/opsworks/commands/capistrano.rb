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
        opt :backup, "Backup old file config before updating", type: String
        opt :variable_name, "Variable name of target host array. Default: domain", type: String
        opt :file, "Path of capistrano role file. Default: ./config/deploy/opsworks.rb", type: String
      end

      config = OpsWorks.config

      client = AWS::OpsWorks::Client.new

      options[:variable_name] ||= "domain"
      instances = []

      config.stacks.each do |stack_id|
        run_with_time "Fetching data for stack with id #{stack_id}..." do
          result = client.describe_instances(stack_id: stack_id)
          instances += result.instances.select { |i| i[:status] != "stopped" }
        end
      end

      instances.reject! { |i| i[:elastic_ip].nil? && i[:public_ip].nil? }
      instances.collect! {|i| i[:elastic_ip] || i[:public_ip] }

      new_contents = "#{PREFIX}\n" <<
                     "set :#{options[:variable_name]}, #{instances.to_s}\n" <<
                     "#{POSTFIX}\n\n"

      path = options[:file] || "./config/deploy/opsworks.rb"

      old_contents = File.read(path)

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
