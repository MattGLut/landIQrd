class LeasesController < ApplicationController
  before_action :set_unit, only: %i[new create]
  before_action :set_lease, only: %i[show edit update destroy]
  before_action :load_tenants, only: %i[new create edit update]

  def show
    authorize @lease
  end

  def new
    @lease = @unit.leases.new
    authorize @lease
  end

  def create
    @lease = @unit.leases.new(lease_params)
    authorize @lease
    if @lease.save
      redirect_to @lease, notice: "Lease created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @lease
  end

  def update
    authorize @lease
    if @lease.update(lease_params)
      redirect_to @lease, notice: "Lease updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @lease
    property = @lease.unit.property
    @lease.destroy
    redirect_to property, notice: "Lease deleted."
  end

  private

  def set_unit
    @unit = Unit.find(params[:unit_id])
  end

  def set_lease
    @lease = Lease.includes(:tenant, unit: :property).find(params[:id])
  end

  def load_tenants
    @tenants = if current_user.admin?
      User.tenant.order(:last_name, :first_name)
    else
      linked_ids = Lease.joins(unit: :property)
                        .where(properties: { landlord_id: current_user.id })
                        .select(:tenant_id)
      invited_emails = LeaseInvitation.joins(unit: :property)
                                      .where(properties: { landlord_id: current_user.id })
                                      .select(:email)
      invited_ids = User.tenant.where(email: invited_emails).select(:id)
      User.tenant.where(id: linked_ids).or(User.tenant.where(id: invited_ids))
           .distinct.order(:last_name, :first_name)
    end
  end

  def lease_params
    params.require(:lease).permit(:tenant_id, :start_date, :end_date, :rent_amount, :deposit_amount, :status, documents: [])
  end
end
