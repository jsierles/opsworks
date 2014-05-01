require 'aws-sdk'
require 'trollop'

require 'opsworks'

module OpsWorks::Commands
  class UpdateStack
    def self.banner
      "Update an Opsworks stack"
    end

    def self.run
      options = Trollop::options do
        banner <<-EOS.unindent
          #{CreateInstances.banner}

          Options:
        EOS
        opt :stack, "Name of Opsworks stack", type: String
        opt :custom_json_path, "Path to the custom JSON file", type: String
      end

      %w(stack).each do |a|
        if !options[a.to_sym]
          Trollop.die(a.to_sym, "#{a} is required")
        end
      end
     
      config = OpsWorks.config

      client = AWS::OpsWorks::Client.new
      
      stacks = client.describe_stacks.data[:stacks]

      stack = stacks.detect {|s| options[:stack] == s[:name] }

      json - File.read(File.expand_path(options[:custom_json_p]))
      client.update_stack(stack_id: stack[:stack_id], custom_json: json)
    end
  end
end
