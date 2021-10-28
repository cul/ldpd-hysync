module Voyager
  module ClientBehavior
    module OracleQueryBehavior

      ORACLE_WAIT_TIMEOUT = 5.seconds

      # From: https://github.com/cul/clio-backend/blob/3ad14e63cf75ceae0f67427d9cdab882ece44132/lib/oracle_connection.rb
      def fill_in_query_placeholders(query, *args)
        options = args.extract_options!
        options.each do |name, value|
          formatted_value = Array(value).collect do |item|
            "'#{item.to_s.gsub("'", "''")}'"
          end.join(',')
          query.gsub!("~#{name}~", formatted_value)
        end
        query
      end

      def execute_select_command_with_retry(query)
        # If the oracle connection takes longer than a certain amount of time,
        # use a Timeout to stop execution so that our code doesn't lock up indefinitely.
        Retriable.retriable on: [Timeout::Error], tries: 3, base_interval: 1 do
          begin
            Timeout.timeout(ORACLE_WAIT_TIMEOUT) do
              return execute_select_command(query)
            end
          rescue Timeout::Error => e
            # Try to cleanup the interrupted OCI connection
            break_oracle_connection!
            # Re-raise error so we can re-try
            raise e
          end
        end
      end

      # From: https://github.com/cul/clio-backend/blob/3ad14e63cf75ceae0f67427d9cdab882ece44132/lib/oracle_connection.rb
      def execute_select_command(query)
        cursor = oracle_connection.parse(query)
        results = []
        cursor.exec
        cursor.fetch_hash do |row|
          results << row
        end
        cursor.close
        results
      end
    end
  end
end
