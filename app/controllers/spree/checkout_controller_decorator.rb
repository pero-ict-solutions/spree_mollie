Spree::CheckoutController.class_eval do
  before_action :pay_with_mollie, only: :update

  private

    def pay_with_mollie
      return unless params[:state] == 'payment'

      pm_id = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(pm_id)

      if payment_method && payment_method.is_a?(Spree::PaymentMethod::Mollie)
        status_object = MolliePaymentService.new(payment_method: payment_method,
                                                 order: @order,
                                                 redirect_url: mollie_check_status_url(@order)).create_payment
        if status_object.mollie_error?
          mollie_error && return
        end

        if status_object.has_error?
          flash[:error] = status_object.errors.join("\n")
          redirect_to checkout_state_path(@order.state) && return
        end
        redirect_to status_object.payment_url
      end
    end

    def mollie_error(e = nil)
      @order.errors[:base] << "Mollie error #{e.try(:message)}"
      render :edit
    end
end
