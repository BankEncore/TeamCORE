# frozen_string_literal: true

require "test_helper"

class AdminDocumentWorkbenchTest < ActionDispatch::IntegrationTest
  setup do
    @agency = Agency.create!(name: "Wb", code: "wb#{SecureRandom.hex(4)}")
    @user = User.create!(
      email: "wb#{SecureRandom.hex(4)}@ex.com",
      password: "password12",
      password_confirmation: "password12"
    )
    UserAgency.create!(user: @user, agency: @agency)
    post login_path, params: { email: @user.email, password: "password12" }
    follow_redirect!
  end

  test "document workbench loads for agency" do
    get admin_document_workbench_path
    assert_response :success
    assert_includes @response.body, "Document workbench"
    assert_includes @response.body, "Pending review"
  end
end
