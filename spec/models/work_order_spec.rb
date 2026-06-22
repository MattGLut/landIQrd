require "rails_helper"

RSpec.describe WorkOrder, type: :model do
  it { is_expected.to belong_to(:unit) }
  it { is_expected.to belong_to(:lease).optional }
  it { is_expected.to belong_to(:created_by).class_name("User") }
  it { is_expected.to have_many(:work_order_assignments).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }

  it do
    is_expected.to define_enum_for(:status)
      .with_values(open: 0, in_progress: 1, on_hold: 2, completed: 3, cancelled: 4)
      .with_prefix
  end

  describe "scopes" do
    let(:landlord) { create(:landlord) }
    let(:property) { create(:property, landlord: landlord) }
    let(:unit) { create(:unit, property: property) }

    it ".for_landlord returns work orders within the landlord's portfolio" do
      mine = create(:work_order, unit: unit)
      create(:work_order)
      expect(WorkOrder.for_landlord(landlord)).to contain_exactly(mine)
    end

    it ".for_contractor returns only assigned work orders" do
      contractor = create(:contractor)
      assigned = create(:work_order, unit: unit)
      create(:work_order_assignment, work_order: assigned, contractor: contractor)
      create(:work_order, unit: unit)
      expect(WorkOrder.for_contractor(contractor)).to contain_exactly(assigned)
    end

    it ".active excludes completed and cancelled" do
      open = create(:work_order, unit: unit, status: :open)
      create(:work_order, unit: unit, status: :completed)
      create(:work_order, unit: unit, status: :cancelled)
      expect(WorkOrder.active).to contain_exactly(open)
    end
  end
end
