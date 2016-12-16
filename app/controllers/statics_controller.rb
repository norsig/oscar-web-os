class StaticsController < ApplicationController

  def index
    redirect_to dashboards_url(subdomain: current_user.organization_short_name) if user_signed_in?
  end

  def robots
    robots = File.read(Rails.root + "config/robots/#{Rails.env}.txt")
    render text: robots, layout: false, content_type: 'text/plain'
  end

end