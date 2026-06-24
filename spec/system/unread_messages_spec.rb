require "rails_helper"

RSpec.describe "Unread messages" do
  let(:tenant) { create(:tenant) }
  let(:landlord) { create(:landlord) }

  it "shows an unread badge in the top navigation" do
    conversation = Conversation.direct_between!(tenant, landlord)
    conversation.messages.create!(author: landlord, body: "Need your input")

    sign_in_and_visit(tenant, conversations_path)
    expect(page).to have_css("header nav span", text: "1")
  end

  it "shows an unread dot on the conversation and clears it after viewing" do
    conversation = Conversation.direct_between!(tenant, landlord)
    conversation.messages.create!(author: landlord, body: "Ping")

    sign_in_and_visit(tenant, conversations_path)
    expect(page).to have_css("span.rounded-full.bg-brand-600")

    click_link conversation.title
    visit conversations_path
    expect(page).not_to have_css("span.rounded-full.bg-brand-600")
  end
end
