class Event < ActiveRecord::Base
  scope :event_exists, lambda {|day|
    where("starts_at >= ? AND ends_at <= ? AND Kind in ('opening', 'appointment')", day.beginning_of_day, day.end_of_day)
  }

  scope :weekly_recurring_events, lambda {
    where(weekly_recurring: true, kind: 'opening')
  }

  scope :non_recurring_events, lambda { |day|
    where("starts_at >= ? AND ends_at <= ? AND weekly_recurring = ? ", day.beginning_of_day, day.end_of_day, false)
  }

  scope :appointments,  lambda { |day|
    where("starts_at >= ? AND ends_at <= ? AND Kind = ?", day.beginning_of_day, day.end_of_day, 'appointment')
  }

  RDV_TIME = 30.minutes

  # Steps
  # 1. Generate an array for 7 days from the given date
  # 2. Generate general opening timings includes weekly recurring events 'opening'
  # 3. Generate appointment timings based on kind 'appointment'
  # 4. (Step 2 - Step 3) => remaining timings - free appointment timings
  # 5. Print the day with the free timings

  def self.availabilities(start_date)
    next_7_days_planning = []
    (0..6).each do |n|
      next_7_days_planning.push(start_date + n.day)
    end

    slots = next_7_days_planning.map do |day|
      event_exists(day).present? ? calculate_slots(day) : []
    end

    next_7_days_planning.each_with_index.map do |day, i|
      { date: day, slots: slots[i] }
    end
  end

  def self.calculate_slots(day)
    slots = []

    #Get weekly re-ocurring events and generate opening time
    weekly_recurring_events.each do |opening|
      slots.push(opening.generate_slots)
    end

    #Get non recurring events and generate opening time
    non_recurring_events(day).each do |opening|
      slots.push(opening.generate_slots)
    end

    #Get appointment events and generate the occupied timings
    appointments(day).each do |appointment|
      slots.push(appointment.generate_slots)
    end

    #Opening time - Occupied time => free timings
    slots[1].present? ? slots[0] - slots[1] : slots[0]
  end

  def format_to_hour(date)
    date.strftime("%H:%M").gsub(/^0/, '')
  end

  def generate_slots
    slots = []
    last_slot = format_to_hour(self[:ends_at] - RDV_TIME)
    slots_added = 0

    while last_slot != slots.last
      slots.push(format_to_hour(self[:starts_at] + slots_added * RDV_TIME))
      slots_added += 1
    end
    slots
  end
end
