module Admin
  class PropertiesController < BaseController
    def index
      @properties = Property.includes(:landlord, :units).order(:name).page(params[:page]).per(PER_PAGE)
    end

    def show
      @property = Property.find(params[:id])
    end
  end
end
