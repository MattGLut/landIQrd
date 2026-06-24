require "rails_helper"

RSpec.describe WorkOrder, type: :model do
  include ActiveJob::TestHelper

  after { clear_enqueued_jobs }

  it { is_expected.to belong_to(:unit) }
  it { is_expected.to belong_to(:lease).optional }
  it { is_expected.to belong_to(:created_by).class_name("User") }
  it { is_expected.to have_many(:work_order_assignments).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }

  it do
    is_expected.to define_enum_for(:status)
      .with_values(
        open: 0,
        pending_tenant: 1,
        pending_management: 2,
        on_hold: 3,
        completed: 4,
        cancelled: 5
      )
      .with_prefix
  end

  it "defaults new work orders to the general category" do
    work_order = create(:work_order)
    expect(work_order.category).to eq("general")
    expect(work_order).to be_category_general
  end

  it "logs a created event after create" do
    work_order = create(:work_order)
    expect(work_order.work_order_events.last.action).to eq("created")
  end

  describe ".categories_for" do
    it "returns base categories for residential units" do
      unit = create(:unit)
      expect(described_class.categories_for(unit)).to eq(described_class::BASE_CATEGORIES)
    end

    it "includes commercial categories for commercial units" do
      unit = create(:unit, :commercial)
      expect(described_class.categories_for(unit)).to include("fire_safety", "structural")
    end

    it "includes land categories for undeveloped units" do
      unit = create(:unit, :undeveloped)
      expect(described_class.categories_for(unit)).to include("site_maintenance", "environmental")
    end
  end

  describe "category validation" do
    it "rejects commercial-only categories on residential units" do
      unit = create(:unit)
      work_order = build(:work_order, unit: unit, category: :fire_safety)
      expect(work_order).not_to be_valid
      expect(work_order.errors[:category]).to include("is not valid for this unit type")
    end

    it "allows land categories on undeveloped units" do
      unit = create(:unit, :undeveloped)
      work_order = build(:work_order, unit: unit, category: :site_maintenance)
      expect(work_order).to be_valid
    end
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

    it ".for_tenant returns work orders created by or on leased units" do
      tenant = create(:tenant)
      other_tenant = create(:tenant)
      leased_unit = create(:unit, property: property)
      create(:lease, unit: leased_unit, tenant: tenant, status: :active)
      created_by_tenant = create(:work_order, unit: unit, created_by: tenant)
      on_leased_unit = create(:work_order, unit: leased_unit, created_by: other_tenant)
      create(:work_order, unit: unit, created_by: other_tenant)

      expect(WorkOrder.for_tenant(tenant)).to contain_exactly(created_by_tenant, on_leased_unit)
    end

    it ".active excludes completed and cancelled" do
      open = create(:work_order, unit: unit, status: :open)
      create(:work_order, unit: unit, status: :completed)
      create(:work_order, unit: unit, status: :cancelled)
      expect(WorkOrder.active).to contain_exactly(open)
    end
  end

  describe "status transitions" do
    let(:landlord) { create(:landlord) }
    let(:property) { create(:property, landlord: landlord) }
    let(:unit) { create(:unit, property: property) }
    let(:tenant) { create(:tenant) }
    let(:work_order) { create(:work_order, unit: unit, created_by: tenant, status: :open) }

    it "allows valid landlord transitions" do
      work_order.transition_to!(:pending_management, user: landlord)

      expect(work_order.reload).to be_status_pending_management
      expect(work_order.work_order_events.last.action).to eq("status_changed")
      expect(work_order.work_order_events.last.metadata).to include("from" => "open", "to" => "pending_management")
    end

    it "rejects invalid transitions" do
      work_order.update!(status: :completed)

      expect {
        work_order.transition_to!(:open, user: landlord)
      }.to raise_error(WorkOrder::InvalidTransition)
    end

    it "cancels with optional reason for landlords" do
      work_order.transition_to!(:cancelled, user: landlord, closure_reason: "Duplicate request")

      work_order.reload
      expect(work_order).to be_status_cancelled
      expect(work_order.closure_reason).to eq("Duplicate request")
      expect(work_order.work_order_events.last.action).to eq("cancelled")
    end

    it "reopens a completed work order to pending management" do
      work_order.update!(status: :completed)

      work_order.transition_to!(:pending_management, user: landlord)

      expect(work_order.reload).to be_status_pending_management
      expect(work_order.work_order_events.last.action).to eq("status_changed")
      expect(work_order.work_order_events.last.metadata).to include("from" => "completed", "to" => "pending_management")
    end

    it "lets a tenant reopen their completed work order" do
      work_order.update!(status: :completed)

      work_order.transition_to!(:pending_management, user: tenant)

      expect(work_order.reload).to be_status_pending_management
      expect(work_order.work_order_events.last.action).to eq("status_changed")
    end
  end

  describe "#close_with_reason!" do
    let(:tenant) { create(:tenant) }
    let(:work_order) { create(:work_order, created_by: tenant, status: :open) }

    it "closes an active work order with a reason" do
      expect {
        work_order.close_with_reason!(user: tenant, closure_reason: "No longer needed")
      }.to have_enqueued_mail(NotificationMailer, :work_order_status_changed)

      work_order.reload
      expect(work_order).to be_status_cancelled
      expect(work_order.closure_reason).to eq("No longer needed")
      expect(work_order.closed_by).to eq(tenant)
      expect(work_order.work_order_events.last.action).to eq("closed")
    end

    it "requires a closure reason" do
      expect {
        work_order.close_with_reason!(user: tenant, closure_reason: "")
      }.to raise_error(WorkOrder::InvalidTransition, "Closure reason is required")
    end

    it "lets a landlord close with a reason" do
      property_landlord = work_order.unit.property.landlord
      expect {
        work_order.close_with_reason!(user: property_landlord, closure_reason: "Resolved offline")
      }.to have_enqueued_mail(NotificationMailer, :work_order_status_changed)

      work_order.reload
      expect(work_order).to be_status_cancelled
      expect(work_order.closed_by).to eq(property_landlord)
      expect(work_order.work_order_events.last.action).to eq("closed")
    end
  end
end
