require "rails_helper"

RSpec.describe "Sessions", type: :request do
  it "sets a remember-me cookie when requested" do
    user = create(:landlord)

    post user_session_path, params: {
      user: { email: user.email, password: "password123", remember_me: "1" }
    }

    expect(response.cookies.keys.grep(/remember/i)).not_to be_empty
  end
end
