require "spec_helper"

RSpec.describe Spree::MollieController do

  before :each do
    @order = create(:completed_order_with_pending_payment)
  end

  describe "when no PaymentMethod available" do
    it 'raises NoMethodError' do
      expect(lambda { post :notify, id: 'TEST_ID', status: 'paid', use_route: :spree}).
        to raise_error(NoMethodError)
    end
  end
end