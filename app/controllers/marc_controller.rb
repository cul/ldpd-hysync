class MarcController < ApplicationController

  before_action :authenticate_http_basic!, only: :sync

  def index
    # just redirecting for now. will have a more useful index later.
    redirect_to action: 'sync'
    return
  end

  def sync
    success = nil
    errors = nil
    duration = Benchmark.realtime do
      success, errors = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG).run(sync_params[:force_update] == 'true')
    end
    render plain: "MARC sync complete! Finished in #{duration} seconds." + (success ? '' : "Errors:\n\n" + errors.join("\n"))
  end

  private

  def sync_params
    params.permit(:force_update)
  end
end
