require 'spec_helper'

describe "Order Paid By Mollie" do
  stub_authorization!

  before(:each) do
    @pm =  create(:mollie_payment_method, preferences: { api_key: 'test_pw5ZHNihuiFKefzBwZVwAdKXt5C4Xe' })
    @order = create(:order_paid_by_mollie, mollie_transaction_id: 'tr_Et8BmUSq7B')
  end

  context "admin visits orders", js: true do

    before(:each) do
      visit spree.admin_path
      click_link "Orders"
    end

    it 'and can see 1 order' do
      expect(page).to have_selector('table#listing_orders tbody tr', :count => 1) # count of orders in table
    end

    it 'and can refund payment' do
      VCR.use_cassette('refund_success') do
        click_link @order.number
        click_link 'Payments'
        find("#content").find("table").first("a").click # click the first object
        click_link('Refund')
        expect(page).to have_content('Mollie refund successful')
      end
    end
  end

end
