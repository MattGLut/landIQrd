class UnitsController < ApplicationController
  include FeatureParams

  before_action :set_property, only: %i[new create]
  before_action :set_unit, only: %i[show edit update destroy]

  def show
    authorize @unit
  end

  def new
    @unit = @property.units.new
    authorize @unit
  end

  def create
    @unit = @property.units.new(unit_params)
    authorize @unit
    if @unit.save
      redirect_to @property, notice: "Unit added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @unit
  end

  def update
    authorize @unit
    if @unit.update(unit_params)
      redirect_to @unit.property, notice: "Unit updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @unit
    property = @unit.property
    @unit.destroy
    redirect_to property, notice: "Unit removed."
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_unit
    @unit = Unit.includes(:property, leases: :tenant).find(params[:id])
  end

  def unit_params
    permitted = params.require(:unit).permit(
      :label, :bedrooms, :bathrooms, :square_feet, :unit_type, :acreage,
      features: PropertyFeatureCatalog.all_keys_for(:unit)
    )
    permitted[:unit_type] = nil if permitted[:unit_type].blank?
    effective_type = permitted[:unit_type].presence || @property&.property_type || @unit&.property&.property_type
    permitted[:features] = build_features_params(permitted[:features], type: effective_type, scope: :unit)
    permitted
  end
end
