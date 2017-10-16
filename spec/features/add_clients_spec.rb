require 'rails_helper'
require 'custom_spec_helper'

feature "Adding clients process" do
  before do
    load_standard_documents
    load_docyt_support
    stub_request(:any, /.*amazonaws.com.*/).to_return(status: 200)
    page.driver.headers = { 'X-USER-TOKEN': advisor.authentication_token }
    page.driver.resize(1280,1024)
    login_as(advisor)
  end

  let(:name)    { Faker::Name.name }
  let(:email)   { Faker::Internet.safe_email }

  let(:advisor) {
    create(:advisor, :confirmed_email,
      standard_category: StandardCategory.first,
      current_workspace_id: ConsumerAccountType::BUSINESS
    )
  }

  let(:client)  { create(:client, advisor: advisor, phone: phone_number, email: email) }

  let(:phone_number)         { generate(:phone).delete('-') }
  let!(:business_partner)    { create(:business_partner, user: advisor) }
  let(:invalid_phone_number) { generate(:phone) }

  let(:check_clients_page) {
    visit '/clients'
    expect(page).to have_content('CLIENTS')
  }

  scenario 'cannot visit page without sign in', js: true, faye: true do
    page.driver.headers = {}
    visit '/clients'
    expect(page).to have_content('SIGN IN')
    expect(page).to have_selector("input[placeholder='Email']")
    expect(page).to have_selector("input[placeholder='Password']")
  end

  scenario 'successfully added client', js: true, faye: true do
    check_clients_page

    find('#add-client').click
    fill_in 'First Name  Middle  Last', with: name
    fill_in 'Email', with: email
    fill_in 'Cell Phone', with: phone_number
    click_on('Add')

    expect(page).to have_content(name)
    expect(page).not_to have_content(email)
    expect(page).not_to have_content(phone_number)
  end

  scenario 'unsuccessfully added client with invalid email', js: true, faye: true do
    check_clients_page

    find('#add-client').click
    fill_in 'First Name  Middle  Last', with: name
    fill_in 'Email', with: name
    fill_in 'Cell Phone', with: phone_number
    click_on('Add')

    expect(page).to have_button('Add')
    expect(page).to have_content('Please enter correct email')
  end

  scenario 'unsuccessfully added client with invalid phone', js: true, faye: true do
    check_clients_page

    find('#add-client').click
    fill_in 'First Name  Middle  Last', with: name
    fill_in 'Email', with: name
    fill_in 'Cell Phone', with: invalid_phone_number
    click_on('Add')

    expect(page).to have_button('Add')
    expect(page).to have_content('Please enter correct phone')
  end

  scenario 'unsuccessfully added client with existing email', js: true, faye: true do
    check_clients_page

    find('#add-client').click
    fill_in 'First Name  Middle  Last', with: name
    fill_in 'Email', with: client.email
    fill_in 'Cell Phone', with: phone_number
    click_on('Add')

    expect(page).to have_button('Add')
    expect(page).to have_content('This email is already in use')
  end

  scenario 'unsuccessfully added client with existing phone', js: true, faye: true do
    check_clients_page

    find('#add-client').click
    fill_in 'First Name  Middle  Last', with: name
    fill_in 'Email', with: email
    fill_in 'Cell Phone', with: client.phone
    click_on('Add')

    expect(page).to have_button('Add')
    expect(page).to have_content('This phone number is already in use')
  end

  scenario 'unsuccessfully added client without advisor name', js: true, faye: true do
    advisor.update(first_name: nil, last_name: nil)
    check_clients_page

    find('#add-client').click
    fill_in 'First Name  Middle  Last', with: name
    fill_in 'Email', with: email
    fill_in 'Cell Phone', with: phone_number
    first('.relative > label').click
    click_on('Add')

    expect(page).to have_button('Add')
    expect(page).to have_content('You need to update your profile with your full name before you invite others')
  end
end
