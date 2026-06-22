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
    @lease = Lease.find(params[:id])
  end

  def load_tenants
    @tenants = User.tenant.order(:last_name, :first_name)
  end

  def lease_params
    params.require(:lease).permit(:tenant_id, :start_date, :end_date, :rent_amount, :deposit_amount, :status, documents: [])
  end
end
