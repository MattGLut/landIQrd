require "rails_helper"

RSpec.describe Message, type: :model do
  it { is_expected.to belong_to(:conversation) }
  it { is_expected.to belong_to(:author).class_name("User") }

  it "requires a body when no files are attached" do
    message = build(:message, body: nil)
    expect(message).not_to be_valid
    expect(message.errors[:body]).to be_present
  end

  it "allows a file attachment without a body" do
    message = build(:message, body: nil)
    message.files.attach(
      io: StringIO.new("attachment contents"),
      filename: "note.txt",
      content_type: "text/plain"
    )
    expect(message).to be_valid
  end

  it "skips turbo broadcast when suppress_realtime_broadcasts is set" do
    message = build(:message)
    Thread.current[:suppress_realtime_broadcasts] = true
    expect(message).not_to receive(:broadcast_append_to)
    message.save!
  ensure
    Thread.current[:suppress_realtime_broadcasts] = false
  end
end
