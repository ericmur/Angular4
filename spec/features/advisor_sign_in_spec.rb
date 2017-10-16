require 'rails_helper'
require 'custom_spec_helper'

feature "Sign in process" do
  before do
    load_standard_documents
    load_docyt_support
  end

  let(:advisor) {
    create(:advisor, :confirmed_email,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      standard_category: StandardCategory.first
    )
  }

  scenario 'Registered advisor try to sign in', js: true, faye: true do
    visit '/sign_in'
    fill_in 'Email',    with: advisor.email
    fill_in 'Password', with: advisor.password
    click_on 'Sign In'

    expect(page).not_to have_content('Sign In')

    expect(page).to have_content("Congratulations! You have successfully signed up for your Docyt web account.")
  end

  scenario 'Non-registered advisor try to sign in', js: true, faye: true do
    visit '/sign_in'
    fill_in 'Email',    with: Faker::Internet.safe_email
    fill_in 'Password', with: Faker::Internet.password
    click_on 'Sign In'
    expect(page).to have_content('Invalid email or password')
  end

  scenario 'Sign in after confirmed email', js: true, faye: true do
    visit '/sign_in?confirmed=true'
    expect(page).to have_content('Your email has been verified. Please sign in using your new email')
    expect(page).to have_selector(:css, 'div#confirm-email-alert')
    expect(page).to have_selector(:css, 'div.alert-success')
    expect(page).to have_selector(:css, 'div.alert')
  end
end
