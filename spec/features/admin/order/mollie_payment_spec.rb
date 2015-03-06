require 'spec_helper'

describe "Order Paid By Mollie" do

  include RSpec::Rails::RequestExampleGroup

  stub_authorization!

  let!(:product) { create(:product, :name => 'iPad') }
  let!(:shipping_method) { create(:shipping_method) }
  before(:each) do
    @pm =  create(:mollie_payment_method, preferences: { api_key: ENV['MOLLIE_TEST_API_KEY'] })
  end

  def fill_in_billing
    within("#billing") do
      fill_in "First Name", :with => "Test"
      fill_in "Last Name", :with => "User"
      fill_in "Street Address", :with => "1 User Lane"
      fill_in "City", :with => "Adamsville"
      select "United States of America", :from => "order_bill_address_attributes_country_id"
      select "Alabama", :from => "order_bill_address_attributes_state_id"
      fill_in "Zip", :with => "35005"
      fill_in "Phone", :with => "555-123-4567"
    end
  end

  def prepare_order_for_payment
    page.driver.block_unknown_urls
    page.driver.allow_url("www.mollie.com")
    visit spree.root_path
    click_link 'iPad'
    click_button 'Add To Cart'
    click_button 'Checkout'
    within("#guest_checkout") do
      fill_in "Email", :with => "test@example.com"
      click_button 'Continue'
    end
    fill_in_billing
    wait_for_ajax
    click_button "Save and Continue"
    # Delivery step doesn't require any action

    VCR.use_cassette('load methods and issuers') do
      click_button "Save and Continue"
      choose "Mollie"
    end
  end

  def emulate_checkout_controller
    @order = Spree::Order.last
    MolliePaymentService.new(payment_method: Spree::PaymentMethod.last,
                             order: @order,
                             redirect_url: "/mollie/check_status/#{@order.number}").create_payment
  end

  def emulate_checkout_pay_flow(expected_redirect)
    emulate_checkout_controller

    # user get's redirected from mollie
    expect(get "/mollie/check_status/#{@order.number}").to redirect_to expected_redirect

    # emulate mollie#notify call from external api
    post '/mollie/notify', id: Spree::Payment.last.transaction_id, use_route: :spree
  end

  def cancel_order
    VCR.use_cassette('failed_order_interaction') do
      # click_button "Save and Continue"
      # click_link "Back to the website"

      emulate_checkout_pay_flow("/checkout/payment")
    end
  end

  def pay_for_order_with_creditcard
    VCR.use_cassette('paid_order_interaction') do
      # click_button "Save and Continue"
      # click_button "Creditcard"
      # click_button "Verder naar uw webshop"

      emulate_checkout_pay_flow("/orders/#{Spree::Order.last.number}")
    end
  end

  shared_examples 'order with 1 payment' do |expected_payment_status|
    before do
      prepare_order_for_payment

      payment_method.call # should be defined by let

      visit spree.admin_path
      click_link "Orders"
    end

    specify { expect(page).to have_selector('table#listing_orders tbody tr', :count => 1 ) } # count of orders in table

    context 'and visits payments.' do
      before do
        within 'table#listing_orders' do
          find('.action-edit').click
        end
        click_link "Payments"
      end

      specify do
        find('#payment_status').should have_content(expected_payment_status)
      end

      it 'can see transaction id' do
        transaction_id = Spree::Payment.last.response_code
        expect( find('table#payments tbody tr') ).to have_content(transaction_id)
      end

      if expected_payment_status == 'paid'
        it 'can refund payment' do
          VCR.use_cassette('paid_order_refund') do
            find("#content").find("table").first("a").click # click first link
            click_link('Refund')
            expect(page).to have_content('Mollie refund successful')
          end
        end
      end
    end
  end

  context "admin visits orders", js: true do
    it_behaves_like 'order with 1 payment', 'paid' do
      let(:payment_method) { Proc.new { pay_for_order_with_creditcard } }
    end

    it "can't see completed order when payment cancelled" do
      prepare_order_for_payment

      cancel_order

      visit spree.admin_path
      click_link "Orders"
      expect(page).not_to have_selector('table#listing_orders tbody tr')
    end
  end
end
