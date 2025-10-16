class HomeController < ApplicationController
  def index
    @qurans = Quran.all
  end
end