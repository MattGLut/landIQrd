# Share the test thread's DB connection with the Puma server thread used by Selenium.
class ActiveRecord::Base
  mattr_accessor :shared_connection
  self.shared_connection = nil

  def self.connection
    shared_connection || super
  end
end

ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(Module.new do
  def connection
    ActiveRecord::Base.shared_connection || super
  end
end)

RSpec.configure do |config|
  config.before(:each, type: :system, js: true) do
    ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
  end

  config.after(:each, type: :system, js: true) do
    ActiveRecord::Base.shared_connection = nil
  end
end
