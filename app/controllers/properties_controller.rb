class PropertiesController < ApplicationController
  before_action :set_property, only: %i[show edit update destroy]

  def index
    authorize Property
    @properties = policy_scope(Property).includes(:units).order(:name)
  end

  def show
    authorize @property
  end

  def new
    @property = current_user.properties.new
    authorize @property
  end

  def create
    @property = current_user.properties.new(property_params)
    authorize @property
    if @property.save
      redirect_to @property, notice: "Property created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @property
  end

  def update
    authorize @property
    if @property.update(property_params)
      redirect_to @property, notice: "Property updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @property
    @property.destroy
    redirect_to properties_path, notice: "Property deleted."
  end

  private

  def set_property
    @property = Property.includes(units: :leases).find(params[:id])
  end

  def property_params
    params.require(:property).permit(:name, :address_line1, :address_line2, :city, :state, :postal_code)
  end
end
