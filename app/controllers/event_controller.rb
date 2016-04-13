class EventController < ApplicationController

  def index
    @test = Event.availabilities(DateTime.parse("2014-09-28"))
    render json: { slots: @test }
  end
end
