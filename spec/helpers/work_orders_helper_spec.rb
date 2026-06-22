require "rails_helper"

RSpec.describe WorkOrdersHelper, type: :helper do
  describe "#work_order_photo_source" do
    let(:work_order) { create(:work_order) }

    before do
      work_order.photos.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )
    end

    let(:photo) { work_order.photos.first }

    it "returns a resized variant when processing is available" do
      processed = instance_double(ActiveStorage::VariantWithRecord)
      variant = instance_double(ActiveStorage::VariantWithRecord, processed: processed)
      allow(photo).to receive(:variable?).and_return(true)
      allow(photo).to receive(:variant).with(resize_to_limit: [ 300, 300 ]).and_return(variant)

      expect(helper.work_order_photo_source(photo)).to eq(processed)
    end

    it "falls back to the original when variant processing fails" do
      allow(photo).to receive(:variable?).and_return(true)
      allow(photo).to receive(:variant).and_raise(LoadError, "libvips not installed")

      expect(helper.work_order_photo_source(photo)).to eq(photo)
    end

    it "returns the original for non-variable attachments" do
      allow(photo).to receive(:variable?).and_return(false)

      expect(helper.work_order_photo_source(photo)).to eq(photo)
    end
  end
end
