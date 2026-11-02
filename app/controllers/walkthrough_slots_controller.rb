class WalkthroughSlotsController < ApplicationController
  before_action :set_job

  def create
    authorize @job, :manage?

    date = parse_date(params[:date])
    times = Array(params[:times]).compact_blank
    duration = params[:duration_minutes].to_i.clamp(15, 240)
    zone = ActiveSupport::TimeZone[params[:timezone].presence || @job.timezone]

    if date.nil? || zone.nil?
      return redirect_to walkthroughs_job_path(@job), alert: "Choose a valid date and timezone."
    end

    created = 0
    Job.transaction do
      @job.update!(job_settings(zone))
      @job.walkthrough_slots.update_all(capacity: @job.slot_capacity)

      times.each do |time|
        start = zone.parse("#{date} #{time}")
        slot = @job.walkthrough_slots.build(starts_at: start, ends_at: start + duration.minutes, capacity: @job.slot_capacity)
        created += 1 if slot.save
      end
    end

    notice = created.positive? ? "Published #{helpers.pluralize(created, "walkthrough slot")}." : "Walkthrough settings saved."
    redirect_to walkthroughs_job_path(@job), notice: notice
  rescue ActiveRecord::RecordInvalid => e
        redirect_to walkthroughs_job_path(@job), alert: e.message
  end

  def destroy
    slot = @job.walkthrough_slots.find(params[:id])
    authorize slot
    slot.destroy
    redirect_to walkthroughs_job_path(@job), notice: "Walkthrough slot removed."
  end

  private

  def set_job
    @job = policy_scope(Job).find(params[:job_id])
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def job_settings(zone)
    {
      timezone: zone.name,
      walkthrough_required: ActiveModel::Type::Boolean.new.cast(params[:walkthrough_required]) || false,
      slot_capacity: params[:slot_capacity].presence || @job.slot_capacity
    }
  end
end
