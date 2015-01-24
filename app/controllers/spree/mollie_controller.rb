module Spree
  class MollieController < Spree::BaseController
    protect_from_forgery except: [:notify, :continue]

    def notify
      MolliePaymentService.new(payment_id: params[:id]).update_payment_status

      render nothing: true, status: :ok
    end
  end
end
