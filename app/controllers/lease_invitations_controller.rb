class LeaseInvitationsController < ApplicationController
  skip_after_action :verify_authorized, only: :show
  skip_after_action :verify_policy_scoped
  skip_before_action :authenticate_user!, only: :show

  before_action :set_unit, only: %i[new create]
  before_action :set_invitation, only: :show

  def show
    if user_signed_in?
      redirect_to authenticated_root_path, alert: "Please sign out before accepting an invitation with a different account."
      return
    end

    unless @invitation.usable?
      redirect_to new_user_registration_path, alert: "This invitation is no longer valid."
      return
    end

    redirect_to new_user_registration_path(invite_token: @invitation.token, email: @invitation.email)
  end

  def new
    @invitation = @unit.lease_invitations.new
    authorize @invitation
  end

  def create
    @invitation = @unit.lease_invitations.new(invitation_params)
    @invitation.invited_by = current_user
    authorize @invitation

    if @invitation.save
      Notifications::Deliver.lease_invitation(@invitation)
      redirect_to @unit, notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_unit
    @unit = Unit.find(params[:unit_id])
  end

  def set_invitation
    @invitation = LeaseInvitation.find_by!(token: params[:token])
  end

  def invitation_params
    params.require(:lease_invitation).permit(
      :email, :start_date, :end_date, :rent_amount, :deposit_amount
    )
  end
end
