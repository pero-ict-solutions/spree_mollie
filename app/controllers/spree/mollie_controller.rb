module Spree
  class MollieController < Spree::BaseController
    protect_from_forgery except: [:notify, :continue]

    def notify
      MolliePaymentService.new(payment_id: params[:id]).update_payment_status

      render nothing: true, status: :ok
    end

    def check_payment_status
      order = Spree::Order.find_by_number(params[:order_id])
      payment_id = order.payments.last.response_code

      MolliePaymentService.new(payment_id: payment_id).update_payment_status

      redirect_to order.reload.paid? ? order_path(order) : checkout_state_path(:payment)
    end
  end
end
