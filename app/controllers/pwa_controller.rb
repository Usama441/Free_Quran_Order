class PwaController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:service_worker]

  def service_worker
    respond_to do |format|
      format.js do
        render file: Rails.root.join('app', 'views', 'pwa', 'service-worker.js'),
               content_type: 'application/javascript',
               layout: false
      end
    end
  end
end
