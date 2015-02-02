Spree::CheckoutController.class_eval do
  before_action :load_mollie_methods, only: :edit
  before_action :pay_with_mollie, only: :update

  private

    def pay_with_mollie
      return unless params[:state] == 'payment'

      pm_id = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(pm_id)

      if payment_method && payment_method.is_a?(Spree::PaymentMethod::Mollie)
        status_object = MolliePaymentService.new(payment_method: payment_method,
                                                 order: @order,
                                                 method: params[:order][:payments_attributes].first[:mollie_method_id],
                                                 issuer: params[:order][:payments_attributes].first[:issuer_id],
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

    def load_mollie_methods
      return unless params[:state] == 'payment'

      payment_method = Spree::PaymentMethod.first
      service = MolliePaymentService.new(payment_method: payment_method)

      @payment_methods = service.payment_methods
      @issuers = service.issuers
    end

    def mollie_error(e = nil)
      @order.errors[:base] << "Mollie error #{e.try(:message)}"
      render :edit
    end
end
