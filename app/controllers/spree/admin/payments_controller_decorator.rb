Spree::Admin::PaymentsController.class_eval do

  def mollie_refund
    status = MolliePaymentService.new(order: @order, payment: @payment).refund_payment
    if status.refunded?
      flash[:success] = Spree.t(:refund_successful, scope: 'mollie')
    else
      flash[:error] = Spree.t(:refund_unsuccessful, scope: 'mollie') + " (#{status.errors.join("\n")})"
    end
    redirect_to admin_order_payments_path(@order)
  end

end
