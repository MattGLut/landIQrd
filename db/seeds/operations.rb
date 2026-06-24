# frozen_string_literal: true

module Seeds
  module Operations
    MESSAGE_SNIPPETS = [
      "Thanks for the update.",
      "Can we schedule this for later this week?",
      "I'll be home after 5pm if that works.",
      "Please let me know when the contractor is on the way.",
      "Following up on this request.",
      "Photos are attached in the work order.",
      "Access code is 4821 for the front gate.",
      "This is still happening — any ETA?"
    ].freeze

    module_function

    def seed!
      Support.log "Seeding work orders and conversations…"
      contractor_cursor = 0

      Support.state[:units].each_with_index do |unit, index|
        next if unit == Support.state[:fixture_unit] || unit == Support.state[:land_unit]
        next if Support.rng.rand > 0.4

        work_order_count = unit == Support.state[:fixture_unit] ? 1 : (Support.rng.rand < 0.3 ? 2 : 1)
        work_order_count.times do |wo_index|
          work_order = create_work_order(unit, index + wo_index)
          Support.state[:work_orders] << work_order

          next if skip_assignment?(work_order)

          contractor = Support.state[:contractors][contractor_cursor % Support.state[:contractors].length]
          contractor_cursor += 1
          assignment = create_assignment(work_order, contractor, index + wo_index)
          seed_work_order_conversation(work_order, assignment)
        end
      end

      seed_fixture_work_orders
      seed_direct_conversations
    end

    def seed_fixture_work_orders
      fixture_unit = Support.state[:fixture_unit]
      fixture_lease = Support.state[:fixture_lease]
      fixture_tenant = Support.state[:fixture_tenant]
      fixture_contractor = Support.state[:fixture_contractor]

      work_order = WorkOrder.find_or_create_by!(
        unit: fixture_unit,
        created_by: fixture_tenant,
        title: "Kitchen faucet leak"
      ) do |record|
        record.lease = fixture_lease
        record.description = "The kitchen faucet drips constantly."
        record.priority = :high
        record.status = :open
        record.category = :plumbing
      end

      assignment = WorkOrderAssignment.find_or_create_by!(work_order: work_order, contractor: fixture_contractor) do |record|
        record.status = :accepted
        record.scheduled_at = 2.days.from_now
      end

      conversation = Conversation.for_work_order!(work_order)
      seed_messages(conversation, [ fixture_tenant, fixture_contractor, fixture_unit.property.landlord ], count: 3)

      land_unit = Support.state[:land_unit]
      land_lease = Support.state[:land_lease]
      land_tenant = Support.state[:tenants].find { |u| u.email == "landtenant@propman.test" }

      if land_unit && land_lease && land_tenant
        land_work_order = WorkOrder.find_or_create_by!(
          unit: land_unit,
          created_by: land_tenant,
          title: "Clear brush along fence line"
        ) do |record|
          record.lease = land_lease
          record.description = "Brush is encroaching on the north fence."
          record.priority = :medium
          record.status = :open
          record.category = :site_maintenance
        end
        Support.state[:work_orders] << land_work_order unless Support.state[:work_orders].include?(land_work_order)
      end

      Support.state[:work_orders] << work_order unless Support.state[:work_orders].include?(work_order)
      Support.state[:fixture_work_order] = work_order
      Support.state[:fixture_assignment] = assignment
    end

    def create_work_order(unit, index)
      active_lease = unit.leases.find_by(status: :active)
      tenant = active_lease&.tenant
      created_by = tenant || unit.property.landlord
      category = Support.work_order_category_for(unit)
      status = Support::WORK_ORDER_STATUSES[index % Support::WORK_ORDER_STATUSES.length]

      WorkOrder.create!(
        unit: unit,
        lease: active_lease,
        created_by: created_by,
        title: Support.work_order_title(category),
        description: "Reported during routine inspection. Needs attention soon.",
        priority: Support.pick(WorkOrder.priorities.keys),
        status: status,
        category: category,
        created_at: Support.rng.rand(1..60).days.ago
      )
    end

    def skip_assignment?(work_order)
      work_order.status_open? || (work_order.status_pending_management? && Support.rng.rand < 0.4)
    end

    def create_assignment(work_order, contractor, index)
      status = Support.pick(%i[pending accepted accepted declined completed])
      scheduled_at = nil

      if status == :accepted
        scheduled_at = if Support.rng.rand < 0.5
          Support.rng.rand(-14..14).days.from_now.change(hour: Support.rng.rand(8..16))
        end
      end

      WorkOrderAssignment.create!(
        work_order: work_order,
        contractor: contractor,
        status: status,
        scheduled_at: scheduled_at,
        created_at: work_order.created_at + 1.hour
      )
    end

    def seed_work_order_conversation(work_order, assignment)
      conversation = Conversation.for_work_order!(work_order)
      participants = [
        work_order.created_by,
        work_order.unit.property.landlord,
        work_order.unit.current_tenant,
        assignment.contractor
      ].compact.uniq

      seed_messages(conversation, participants, count: Support.rng.rand(2..5))
    end

    def seed_direct_conversations
      landlords = Support.state[:landlords]
      tenants = Support.state[:tenants].first(8)
      contractors = Support.state[:contractors]

      4.times do |index|
        landlord = landlords[index % landlords.length]
        tenant = tenants[index]
        next unless tenant

        conversation = Conversation.direct_between!(landlord, tenant)
        seed_messages(conversation, [ landlord, tenant ], count: Support.rng.rand(2..4))
      end

      4.times do |index|
        landlord = landlords[index % landlords.length]
        contractor = contractors[index % contractors.length]
        conversation = Conversation.direct_between!(landlord, contractor)
        seed_messages(conversation, [ landlord, contractor ], count: Support.rng.rand(2..4))
      end
    end

    def seed_messages(conversation, authors, count:)
      return if conversation.messages.count >= count

      count.times do |message_index|
        author = authors[message_index % authors.length]
        body = Support.pick(MESSAGE_SNIPPETS)
        timestamp = (count - message_index).days.ago + Support.rng.rand(0..12).hours

        conversation.messages.create!(
          author: author,
          body: body,
          created_at: timestamp,
          updated_at: timestamp
        )
      end

      stagger_read_receipts(conversation, authors)
    end

    def stagger_read_receipts(conversation, authors)
      authors.each_with_index do |user, index|
        participant = conversation.conversation_participants.find_by(user: user)
        next unless participant

        if index.even?
          participant.update!(last_read_at: Time.current)
        else
          participant.update!(last_read_at: 3.days.ago)
        end
      end
    end
  end
end
