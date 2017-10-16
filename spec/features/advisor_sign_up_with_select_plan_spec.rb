require 'rails_helper'
require 'custom_spec_helper'

feature "Sign up process" do
  before do
    load_standard_documents
    load_docyt_support
    page.driver.headers = { 'X-USER-TOKEN': advisor.authentication_token }
    page.driver.resize(1280,1440)
    visit '/clients'
  end

  let(:advisor) { create(:advisor, :confirmed_email, standard_category: nil) }

  scenario 'Successfully complete free account details', js: true, faye: true do
    find(:css, "input[class$='user-name-js']").set(Faker::Name.name)

    click_button('Continue')

    expect(page).not_to have_content('Congratulations! You have successfully signed up for your Docyt web account.')

    expect(page).to have_content('My Documents')
  end

  scenario 'Successfully complete family account details', js: true, faye: true do
    page.driver.browser.js_errors = false

    find(:css, "input[class$='user-name-js']").set(Faker::Name.name)

    find('.family-try-free-js').click

    expect(page).to have_content('Congratulations! You have successfully signed up for your Docyt web account.')
    expect(page).to have_content('To get started, complete your account details below.')

    expect(page).to have_content('Please add a credit card to start your trial.')
  end

  scenario 'Successfully complete business account details', js: true, faye: true do
    find(:css, "input[class$='user-name-js']").set(Faker::Name.name)

    find('.biz-try-free-js').click

    expect(page).to have_content('Congratulations! You have successfully signed up for your Docyt web account.')
    expect(page).to have_content('To get started, complete your account details below.')

    expect(page).to have_content('Tell us about your business')
  end
end
