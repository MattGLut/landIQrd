module SystemHelpers
  def sign_in_and_visit(user, path = authenticated_root_path)
    sign_in user
    visit path
  end

  def mobile_viewport
    page.driver.browser.manage.window.resize_to(375, 812) if page.driver.respond_to?(:browser)
  end

  def desktop_viewport
    page.driver.browser.manage.window.resize_to(1400, 900) if page.driver.respond_to?(:browser)
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
