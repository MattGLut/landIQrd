class ContractorsController < ApplicationController
  before_action :set_contractor, only: :show

  def index
    authorize User, policy_class: ContractorPolicy
    @category_filter = params[:category].presence
    @contractors = policy_scope(User, policy_scope_class: ContractorPolicy::Scope)
                   .includes(:contractor_portfolio_items, avatar_attachment: :blob)

    if @category_filter
      @contractors = @contractors.joins(:contractor_portfolio_items)
                                 .where(contractor_portfolio_items: { category: @category_filter })
                                 .distinct
    end
  end

  def show
    authorize @contractor, policy_class: ContractorPolicy
    @portfolio_items = @contractor.contractor_portfolio_items
                                    .includes(photos_attachments: :blob)
                                    .ordered
  end

  private

  def set_contractor
    @contractor = User.contractor.find(params[:id])
  end
end
