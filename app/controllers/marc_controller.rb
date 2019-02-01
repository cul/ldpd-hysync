class MarcController < ApplicationController

  before_action :authenticate_http_basic!, only: :sync

  def index
    # just redirecting for now. will have a more useful index later.
    redirect_to action: 'sync'
    return
  end

  def sync
    duration = Benchmark.realtime do
      Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG).run(sync_params[:force_update] == 'true')
    end
    render plain: "MARC sync complete! Finished in #{duration} seconds."

    # results_found = 0
    # duration = Benchmark.realtime do
    #   z3950_config = VOYAGER_CONFIG['z3950']
    #   query_type = 2
    #   query_field = 1
    #   query_value = '11561600'
    #
    #   ZOOM::Connection.open(z3950_config['host'], z3950_config['port']) do |conn|
    #     conn.database_name = z3950_config['database_name']
    #     conn.preferred_record_syntax = 'USMARC'
    #     search_string = "@attr #{query_type}=#{query_field} #{query_value}"
    #     Rails.logger.debug("Z39.50 search: #{search_string}")
    #     result_set = conn.search(search_string)
    #     # for i in 0..(result_set.length - 1) do
    #     #   bib_id = bib_id_for_zoom_record(result_set[i])
    #     #   puts 'found: ' + bib_id
    #     # end
    #     results_found = result_set.length
    #   end
    # end
    # render plain: "Test complete! Found #{results_found} records. Finished in #{duration} seconds."

  end

  private

  def sync_params
    params.permit(:force_update)
  end
end
