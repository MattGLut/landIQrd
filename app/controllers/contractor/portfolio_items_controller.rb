module Contractor
  class PortfolioItemsController < BaseController
    before_action :set_portfolio_item, only: %i[edit update destroy]

    def index
      authorize ContractorPortfolioItem
      @portfolio_items = policy_scope(ContractorPortfolioItem).includes(photos_attachments: :blob).ordered
    end

    def new
      @portfolio_item = current_user.contractor_portfolio_items.build(
        position: ContractorPortfolioItem.next_position_for(current_user)
      )
      authorize @portfolio_item
    end

    def create
      @portfolio_item = current_user.contractor_portfolio_items.build(portfolio_item_params)
      authorize @portfolio_item

      if @portfolio_item.save
        redirect_to contractor_portfolio_items_path, notice: "Portfolio item added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @portfolio_item
    end

    def update
      authorize @portfolio_item
      if @portfolio_item.update(portfolio_item_params)
        redirect_to contractor_portfolio_items_path, notice: "Portfolio item updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @portfolio_item
      @portfolio_item.destroy
      redirect_to contractor_portfolio_items_path, notice: "Portfolio item removed."
    end

    private

    def set_portfolio_item
      @portfolio_item = current_user.contractor_portfolio_items.find(params[:id])
    end

    def portfolio_item_params
      params.require(:contractor_portfolio_item).permit(:title, :description, :category, :position, photos: [])
    end
  end
end
