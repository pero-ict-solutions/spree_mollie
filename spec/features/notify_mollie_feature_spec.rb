require 'spec_helper'

describe Spree::MollieController do

  include RSpec::Rails::ControllerExampleGroup

  before :each do
    @pm =  create(:mollie_payment_method, preferences: { api_key: 'test_pw5ZHNihuiFKefzBwZVwAdKXt5C4Xe' })
  end

  context 'notify' do
    context 'when payment is paid' do
      it 'payment returns the paid state' do
        VCR.use_cassette('get_status_paid') do
          order = create(:completed_order_with_pending_payment, mollie_transaction_id: 'tr_dkiVfRMs4W')
          order.payments.last.started_processing!
          expect {
               post :notify, id: 'tr_dkiVfRMs4W', use_route: :spree
             }.to change{ order.reload.payment_state }.from('balance_due').to('paid')
        end
      end
    end

    context 'when payment is cancelled' do
      it 'payment returns the failed state' do
        VCR.use_cassette('get_status_cancelled') do
          order = create(:completed_order_with_pending_payment, mollie_transaction_id: 'tr_kKFSWQRRwy')
          order.payments.last.started_processing!
          expect {
            post :notify, id: 'tr_kKFSWQRRwy', use_route: :spree
          }.to change{ order.reload.payment_state }.from('balance_due').to('failed')
        end
      end
    end
  end
end