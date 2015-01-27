require 'spec_helper'
RSpec.describe Spree::CheckoutController do

  before :each do
    @order = create(:order_with_totals)
  end

  describe 'Checkout payment:' do
    it 'prepare payment for Mollie' do
      expect(lambda {patch :update, payment_method_id: 1, state: 'open', use_route: :spree}).
        to raise_error(NoMethodError)
    end
  end
end