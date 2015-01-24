require 'mollie'

class MolliePaymentService
  class StatusObject
    attr_reader :transaction_id, :redirect_url, :errors, :payment_url, :response_status

    def initialize(response={})
      @response_status = response['status']
      @errors = []
      @transaction_id = response['id']
      @redirect_url = response['redirectUrl']
      @payment_url = response['links']['paymentUrl'] if response['links']
      @mollie_error = false
    end

    def open?
      @response_status == 'open'
    end

    def refunded?
      @response_status == 'refunded'
    end

    def has_error?
      !@errors.empty?
    end

    def mollie_error=(val)
      @mollie_error = val
    end

    def mollie_error?
      @mollie_error
    end

    def add_error(error = '')
      @errors << error
      self
    end
  end

  def initialize(params = {})
    @payment_id = params[:payment_id]
    @order = params[:order]
    @redirect_url = params[:redirect_url]
    @payment_method = params[:payment_method]
    @payment = params[:payment]
  end

  def update_payment_status
    response = payment_status_in_mollie(@payment_id)

    order = Spree::Order.where(mollie_transaction_id: response['id']).first
    if order && order.payments
      payment = order.payments.last

      unless payment.completed? || payment.failed?
        case response['status']
          when 'cancelled', 'expired'
            payment.failure!
          when 'pending'
            payment.pend!
          when 'paid', 'paidout'
            payment.complete!
        end
      end
    end

  end

  def create_payment
    amount = @order.total
    description = "Order #{@order.number}"
    response = mollie_client.prepare_payment(amount, description, @redirect_url)
    status_object = StatusObject.new(response)
    if status_object.open?
      payment = @order.payments.build(
          payment_method_id: @payment_method.id,
          amount: @order.total,
          state: 'checkout'
      )

      unless payment.save
        status_object.add_error(payment.errors.full_messages.join("\n"))
      end
      @order.update_attribute(:mollie_transaction_id, status_object.transaction_id)

      unless @order.next
        status_object.add_error(@order.errors.full_messages.join("\n"))
      end

      payment.pend!
    else
      status_object.mollie_error = true
    end

    status_object
  end

  def refund_payment
    response = mollie_client.refund_payment(@order.mollie_transaction_id)

    status = response['error'] ? response['error']['message'] : response['payment']['status']
    status_object = StatusObject.new('status' => status)

    if status_object.refunded?
      default_reason = Spree::RefundReason.find_or_create_by(name: Spree.t(:default_refund_reason, scope: 'mollie'))
      @payment.refunds.create!(transaction_id: response[:id], amount: @payment.amount, reason: default_reason)
    else
      status_object.add_error(status_object.response_status)
    end

    status_object
  end

  private

    def payment_status_in_mollie(payment_id)
      mollie_client.payment_status(payment_id)
    end

    def mollie_client
      @client ||= begin
        api_key = Spree::PaymentMethod::Mollie.first.get_preference(:api_key)
        Mollie::Client.new(api_key)
      end
    end
end
