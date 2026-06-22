require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:base_params) do
    {
      user: {
        first_name: "Ada",
        last_name: "Lovelace",
        email: "ada@example.com",
        phone: "555-1234",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  it "creates a landlord when that role is chosen" do
    params = base_params.deep_merge(user: { role: "landlord", company_name: "Acme Realty" })
    expect { post user_registration_path, params: params }.to change(User, :count).by(1)
    expect(User.last.role).to eq("landlord")
  end

  it "prevents privilege escalation to admin at sign up" do
    params = base_params.deep_merge(user: { role: "admin" })
    post user_registration_path, params: params
    expect(User.last.role).to eq("tenant")
  end
end
