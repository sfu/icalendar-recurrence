require 'spec_helper'

describe Icalendar::Recurrence::Schedule do
  describe "#occurrences_between" do
    let(:example_occurrence) do
      daily_event = example_event :daily
      schedule = Schedule.new(daily_event)
      schedule.occurrences_between(Date.parse("2014-02-01"), Date.parse("2014-03-01")).first
    end

    it "returns object that responds to start_time and end_time" do
      expect(example_occurrence).to respond_to :start_time
      expect(example_occurrence).to respond_to :end_time
    end

    it "returns occurrences within range, including duration spanning #start_time " do
      schedule = Schedule.new(example_event(:week_long))
      occurrences = schedule.occurrences_between(Time.parse("2014-01-13T09:00:00-08:00"), Date.parse("2014-01-20"), spans: true)

      expect(schedule.start_time).to eq(Time.parse("2014-01-13T08:00:00-08:00"))
      expect(occurrences.count).to eq(7)
    end

    context "timezoned event" do
      let(:example_occurrence) do
        timezoned_event = example_event :first_saturday_of_month
        schedule = Schedule.new(timezoned_event)
        example_occurrence = schedule.occurrences_between(Date.parse("2014-02-01"), Date.parse("2014-03-01")).first
      end

      it "returns object that responds to #start_time and #end_time (timezoned example)" do
        expect(example_occurrence).to respond_to :start_time
        expect(example_occurrence).to respond_to :end_time
      end
    end
  end

  describe "#all_occurrences" do
    let(:example_occurrences) do
      weekly_event = example_event :weekly_with_count
      schedule = Schedule.new(weekly_event)
      schedule.all_occurrences
    end

    let(:example_occurrence) { example_occurrences.first }

    it "returns object that responds to start_time and end_time" do
      expect(example_occurrence).to respond_to :start_time
      expect(example_occurrence).to respond_to :end_time
    end

    it "returns all occurrences" do
      expect(example_occurrences.count).to eq(151)
    end
  end

  describe "#ice_cube_schedule" do
    it "handles multiple exception dates properly" do
      test_events = example_event :multiple_exdate
      schedule = Schedule.new(test_events)
      ice_cube_schedule = schedule.ice_cube_schedule

      expect(ice_cube_schedule.occurring_at?(Time.parse("2014-02-03T16:00:00-08:00"))).to eq(true)
      expect(ice_cube_schedule.occurring_at?(Time.parse("2014-02-10T16:00:00-08:00"))).to eq(false)
      expect(ice_cube_schedule.occurring_at?(Time.parse("2014-02-17T16:00:00-08:00"))).to eq(false)
      expect(ice_cube_schedule.occurring_at?(Time.parse("2014-02-24T16:00:00-08:00"))).to eq(true)
    end

    it "returns schedule in the proper timezone observing DST" do
      test_events = example_event :exdate_in_different_dst
      schedule = Schedule.new(test_events)
      ice_cube_schedule = schedule.ice_cube_schedule
      start_times = ice_cube_schedule.next_occurrences(20, Time.parse('2018-09-01')).map(&:start_time)

      # Before time change
      expect(start_times).to include(Time.parse("2018-09-04T10:00:00-07:00"))
      expect(start_times).not_to include(Time.parse("2018-09-04T10:00:00-08:00"))

      # After time change
      expect(start_times).not_to include(Time.parse("2018-11-06T10:00:00-07:00"))
      expect(start_times).to include(Time.parse("2018-11-06T10:00:00-08:00"))
    end
  end

  context "given an event without an end time" do
    let(:schedule) do
      weekly_event = example_event :weekly_with_count # has 1 hour duration
      allow(weekly_event).to receive(:end).and_return(nil)
      Schedule.new(weekly_event)
    end

    it "calculates end time based on start_time and duration" do
      expect(schedule.end_time).to eq(schedule.start_time + 1.hour)
    end
  end

end
