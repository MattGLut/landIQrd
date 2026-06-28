require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "access control" do
    it "redirects non-admins away from the admin dashboard" do
      sign_in create(:landlord)
      get admin_dashboard_path
      expect(response).to redirect_to(root_path)
    end

    it "allows admins in" do
      sign_in create(:admin)
      get admin_dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "user management" do
    before { sign_in create(:admin) }

    it "lists users" do
      create(:landlord, first_name: "Lana", last_name: "Lord")
      get admin_users_path
      expect(response.body).to include("Lana")
    end

    it "paginates users" do
      create_list(:tenant, Admin::BaseController::PER_PAGE + 1)

      get admin_users_path
      expect(response.body).to include("Showing 1–#{Admin::BaseController::PER_PAGE} of #{User.count}")

      get admin_users_path, params: { page: 2 }
      expect(response.body).to include("Showing #{Admin::BaseController::PER_PAGE + 1}–#{User.count} of #{User.count}")
    end

    it "paginates properties" do
      landlord = create(:landlord)
      create_list(:property, Admin::BaseController::PER_PAGE + 1, landlord: landlord)

      get admin_properties_path
      expect(response.body).to include("Showing 1–#{Admin::BaseController::PER_PAGE} of #{Property.count}")

      get admin_properties_path, params: { page: 2 }
      expect(response.body).to include("Showing #{Admin::BaseController::PER_PAGE + 1}–#{Property.count} of #{Property.count}")
    end

    it "paginates work orders" do
      unit = create(:unit)
      create_list(:work_order, Admin::BaseController::PER_PAGE + 1, unit: unit)

      get admin_work_orders_path
      expect(response.body).to include("Showing 1–#{Admin::BaseController::PER_PAGE} of #{WorkOrder.count}")

      get admin_work_orders_path, params: { page: 2 }
      expect(response.body).to include("Showing #{Admin::BaseController::PER_PAGE + 1}–#{WorkOrder.count} of #{WorkOrder.count}")
    end

    it "paginates conversations" do
      unit = create(:unit)
      create_list(:work_order, Admin::BaseController::PER_PAGE + 1, unit: unit).each do |work_order|
        Conversation.for_work_order!(work_order)
      end

      get admin_conversations_path
      expect(response.body).to include("Showing 1–#{Admin::BaseController::PER_PAGE} of #{Conversation.count}")

      get admin_conversations_path, params: { page: 2 }
      expect(response.body).to include("Showing #{Admin::BaseController::PER_PAGE + 1}–#{Conversation.count} of #{Conversation.count}")
    end

    it "creates a user with the chosen role" do
      expect {
        post admin_users_path, params: {
          user: {
            first_name: "New", last_name: "Admin", email: "newadmin@example.com",
            role: "admin", password: "password123", password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)
      expect(User.find_by(email: "newadmin@example.com").role).to eq("admin")
    end

    it "updates a user" do
      user = create(:landlord, first_name: "Before")
      patch admin_user_path(user), params: { user: { first_name: "After", role: "landlord" } }
      expect(user.reload.first_name).to eq("After")
    end

    it "deletes another user" do
      user = create(:tenant)
      expect {
        delete admin_user_path(user)
      }.to change(User, :count).by(-1)
      expect(response).to redirect_to(admin_users_path)
    end
  end

  describe "self-deletion guard" do
    it "prevents an admin from deleting their own account" do
      admin = create(:admin)
      sign_in admin
      expect {
        delete admin_user_path(admin)
      }.not_to change(User, :count)
      expect(response).to redirect_to(admin_users_path)
    end
  end
end
