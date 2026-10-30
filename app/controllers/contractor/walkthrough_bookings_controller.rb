module Contractor
  class WalkthroughBookingsController < BaseController
    def index
      authorize WalkthroughBooking
      bookings = policy_scope(WalkthroughBooking).confirmed
                   .includes(walkthrough_slot: { job: :property })
                   .joins(:walkthrough_slot)
                   .order("walkthrough_slots.starts_at")
      @upcoming = bookings.select { |booking| !booking.walkthrough_slot.past? }
      @past = bookings.select { |booking| booking.walkthrough_slot.past? }.reverse
    end

    def create
      job = policy_scope(Job).find(params[:available_job_id])
      slot = job.walkthrough_slots.find(params[:slot_id])
      booking = WalkthroughBooking.new(walkthrough_slot: slot, contractor: current_user)
      authorize booking

      saved = slot.with_lock { booking.save }

      if saved
        redirect_to contractor_available_job_path(job), notice: "Walkthrough reserved for #{slot.day_label}, #{slot.time_range_label}."
      else
        redirect_to contractor_available_job_path(job), alert: booking.errors.full_messages.to_sentence
      end
    end

    def destroy
      booking = policy_scope(WalkthroughBooking).find(params[:id])
      authorize booking
      booking.cancel!
      redirect_to contractor_walkthrough_bookings_path, notice: "Walkthrough cancelled."
    end
  end
end
