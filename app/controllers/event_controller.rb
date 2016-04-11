class EventController < ApplicationController

  def index
    @test = Event.availabilities(DateTime.parse("2014-08-04"))
    render json: { slots: @test }
  end
end
