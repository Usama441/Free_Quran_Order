class HomeController < ApplicationController
  layout 'application'

  def index
    @qurans = Quran.all
  end

  def about
    # About page - no additional data needed
  end
end
