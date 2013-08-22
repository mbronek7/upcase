require 'spec_helper'

feature 'Visitor is asked to create a user before subscription' do

  VALID_SANDBOX_CREDIT_CARD_NUMBER = '4111111111111111'

  background do
    create_plan
    create_mentors
    sign_out
  end

  scenario 'visitor subscribes and is assigned a mentor' do
    create(:user, name: 'Chad Pytel', available_to_mentor: true)
    create(:user, name: 'Ben Orenstein', available_to_mentor: true)

    visit prime_path
    click_landing_page_call_to_action

    mentor_name = /This is (.*)/.match(find('.mentor figcaption strong').text)[1]
    click_link 'Choose'

    expect_to_be_on_subscription_purchase_page

    user = build(:user)
    fill_in 'Name', with: user.name
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'GitHub username', with: 'cpytel'
    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect(current_path).to eq products_path
    expect_to_see_mentor(mentor_name)
  end

  scenario 'visitor attempts to subscribe and creates email/password user' do
    attempt_to_subscribe

    expect_to_be_on_subscription_purchase_page
    expect_to_see_password_required
    expect_to_see_email_required

    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect_to_see_password_error
    expect_to_see_email_error

    user = build(:user)
    fill_in 'Name', with: user.name
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'GitHub username', with: 'cpytel'
    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect(current_path).to eq products_path
    expect(page).to have_content(I18n.t('purchase.flashes.success', name: plan.name))
  end

  scenario 'visitor attempts to purchase with same email address that user exists in system' do
    existing_user = create(:user)

    attempt_to_subscribe
    expect_to_be_on_subscription_purchase_page

    fill_in 'Name', with: existing_user.name
    fill_in 'Email', with: existing_user.email
    fill_in 'Password', with: 'password'
    fill_in 'GitHub username', with: 'cpytel'
    fill_out_subscription_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect(page).not_to have_content(I18n.t('purchase.flashes.success', name: plan.name))

    expect_to_see_email_error("has already been taken")
  end

  scenario 'visitor attempts to subscribe and creates github user' do
    attempt_to_subscribe

    expect_to_be_on_subscription_purchase_page
    click_link 'with GitHub'

    expect_to_be_on_subscription_purchase_page

    expect(page).not_to have_content 'Password'

    fill_out_credit_card_form_with VALID_SANDBOX_CREDIT_CARD_NUMBER

    expect(current_path).to eq products_path
    expect(page).to have_content(I18n.t('purchase.flashes.success', name: plan.name))
  end

  def expect_to_be_on_subscription_purchase_page
    expect(current_url).to eq new_plan_purchase_url(plan)
  end

  def expect_to_see_email_required
    expect(page).to have_css('#purchase_password_input abbr[title=required]')
  end

  def expect_to_see_password_required
    expect(page).to have_css('#purchase_password_input abbr[title=required]')
  end

  def expect_to_see_email_error(text = "can't be blank")
    expect(page).to have_css(
      '#purchase_email_input.error p.inline-errors',
      text: text
    )
  end

  def expect_to_see_password_error
    expect(page).to have_css(
      '#purchase_password_input.error p.inline-errors',
      text: "can't be blank"
    )
  end

  def expect_to_see_mentor(mentor_name)
    expect(page).to have_css('section.mentor h3', text: 'Your Mentor')
    within 'section.mentor h2' do
      expect(page).to have_content(mentor_name)
    end
  end

  def create_plan
    @plan = create(:plan)
  end

  def sign_out
    visit root_path(as: nil)
  end

  def attempt_to_subscribe
    visit prime_path
    click_landing_page_call_to_action
    click_link 'Choose'
  end

  def current_user
    @current_user
  end

  def plan
    @plan
  end
end
