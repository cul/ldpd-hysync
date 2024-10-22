namespace :hysync do
  namespace :test do
    task :check_oracle_connection => :environment do
      puts "Attempting to connect to Voyager at: #{VOYAGER_CONFIG[:oracle][:host]}:#{VOYAGER_CONFIG[:oracle][:port]} ..."
      client = Voyager::Client.new(VOYAGER_CONFIG)
      puts "Connection available? #{client.oracle_connection.ping}"
    rescue OCIError => e
      puts "Connection available? false (Error: #{e.message})"
    end

    task :check_oci8_encoding => :environment do
      puts "OCI8 encoding is: #{OCI8.encoding.inspect}"
    end
  end
end
