class ContractorRelationshipsController < ApplicationController
  before_action :set_relationship, only: %i[update destroy accept decline request_again]

  def index
    authorize ContractorRelationship
    @relationships = policy_scope(ContractorRelationship).includes(:landlord).order(:status, created_at: :desc)
  end

  def create
    @relationship = current_user.contractor_relationships.new(relationship_params)
    @relationship.landlord = current_user
    authorize @relationship

    if @relationship.save
      Notifications::Deliver.relationship_requested(@relationship, actor: current_user)
      redirect_to contractor_path(@relationship.contractor),
                  notice: "Request sent. #{@relationship.contractor.display_name} needs to accept before you can assign a quick job."
    else
      redirect_to relationship_return_path, alert: @relationship.errors.full_messages.to_sentence
    end
  end

  def update
    authorize @relationship

    if @relationship.update(relationship_params.except(:contractor_id))
      redirect_to contractor_path(@relationship.contractor), notice: "Contact updated."
    else
      redirect_to contractor_path(@relationship.contractor), alert: @relationship.errors.full_messages.to_sentence
    end
  end

  def accept
    authorize @relationship
    @relationship.update!(status: :accepted)
    Notifications::Deliver.relationship_responded(@relationship, actor: current_user)
    redirect_to contractor_relationships_path, notice: "Contact accepted."
  end

  def decline
    authorize @relationship
    @relationship.update!(status: :declined)
    Notifications::Deliver.relationship_responded(@relationship, actor: current_user)
    redirect_to contractor_relationships_path, notice: "Contact declined."
  end

  def request_again
    authorize @relationship
    @relationship.update!(status: :pending)
    Notifications::Deliver.relationship_requested(@relationship, actor: current_user)
    redirect_to contractor_path(@relationship.contractor), notice: "Request sent again."
  end

  def destroy
    authorize @relationship
    contractor = @relationship.contractor
    @relationship.destroy
    redirect_to contractor_path(contractor), notice: "Contact removed. Quick jobs for this contractor are no longer available."
  end

  private

  def set_relationship
    scope = current_user.contractor? ? current_user.landlord_relationships : current_user.contractor_relationships
    @relationship = scope.find(params[:id])
  end

  def relationship_params
    params.require(:contractor_relationship).permit(:contractor_id, :kind)
  end

  def relationship_return_path
    contractor_id = @relationship.contractor_id
    return contractors_path unless User.contractor.exists?(contractor_id)

    contractor_path(contractor_id)
  end
end
