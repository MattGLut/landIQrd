module FileFixtureHelpers
  def file_fixture_path(name)
    Rails.root.join("spec/fixtures/files", name)
  end
end

RSpec.configure do |config|
  config.include FileFixtureHelpers
  config.include ActionDispatch::TestProcess::FixtureFile, type: :request
end
