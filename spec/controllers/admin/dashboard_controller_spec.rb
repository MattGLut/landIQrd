require "rails_helper"

RSpec.describe Admin::DashboardController, type: :controller do
  describe "GET #show" do
    let(:admin) { create(:admin) }

    before do
      create(:landlord)
      create(:tenant)
      create(:property)
      6.times { create(:work_order, status: :open) }
      create(:work_order, status: :completed)
      create(:conversation)
      sign_in admin
    end

    it "loads aggregate dashboard counts and recent work orders" do
      get :show

      expect(assigns(:users_count)).to eq(User.count)
      expect(assigns(:properties_count)).to eq(Property.count)
      expect(assigns(:work_orders_count)).to eq(WorkOrder.count)
      expect(assigns(:open_work_orders_count)).to eq(WorkOrder.active.count)
      expect(assigns(:conversations_count)).to eq(Conversation.count)
      expect(assigns(:users_by_role)).to eq(User.group(:role).count)
      expect(assigns(:recent_work_orders).size).to eq(5)
      expect(assigns(:recent_work_orders)).to eq(
        WorkOrder.includes(unit: :property).order(created_at: :desc).limit(5).to_a
      )
    end
  end
end
