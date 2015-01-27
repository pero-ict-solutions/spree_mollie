require 'spec_helper'

describe Spree::MollieController do

  context 'notify' do
    let(:order) do
      order = create(:order_with_pending_mollie_payment)
      order.payments.last.started_processing!
      order
    end

    context 'when payment is paid' do
      it 'payment returns the paid state' do
        VCR.use_cassette('get_status_paid') do
          order.payments.last.update(response_code: 'tr_dkiVfRMs4W')

          expect {
               post :notify, id: 'tr_dkiVfRMs4W', use_route: :spree
             }.to change{ order.reload.payment_state }.from('balance_due').to('paid')
        end
      end
    end

    context 'when payment is cancelled' do
      it 'payment returns the failed state' do
        VCR.use_cassette('get_status_cancelled') do
          order.payments.last.update(response_code: 'tr_kKFSWQRRwy')

          expect {
            post :notify, id: 'tr_kKFSWQRRwy', use_route: :spree
          }.to change{ order.reload.payment_state }.from('balance_due').to('failed')
        end
      end
    end
  end
end