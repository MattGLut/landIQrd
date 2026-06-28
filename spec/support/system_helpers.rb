module SystemHelpers
  def sign_in_and_visit(user, path = authenticated_root_path)
    sign_in user
    visit path
  end

  def mobile_viewport
    page.driver.browser.manage.window.resize_to(375, 812) if page.driver.respond_to?(:browser)
  end

  def sign_out_via_header
    within("header") do
      click_button "Sign out", match: :first
    end
  end
  def desktop_viewport
    page.driver.browser.manage.window.resize_to(1400, 900) if page.driver.respond_to?(:browser)
  end

  def set_reset_password_token(user)
    raw, enc = Devise.token_generator.generate(User, :reset_password_token)
    user.update!(reset_password_token: enc, reset_password_sent_at: Time.current)
    raw
  end

  def set_toggle(id, checked:)
    field = find("##{id}", visible: :all)
    return if field.checked? == checked

    find("label[for='#{id}']").click
  end

  def check_toggle(id)
    set_toggle(id, checked: true)
  end

  def uncheck_toggle(id)
    set_toggle(id, checked: false)
  end

  def within_dashboard_panel(title, &block)
    panel = find("h2", text: title).find(:xpath, "./ancestor::div[contains(@class, 'rounded-2xl')][1]")
    within(panel, &block)
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
