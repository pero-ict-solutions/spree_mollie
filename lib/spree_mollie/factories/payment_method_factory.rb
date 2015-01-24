FactoryGirl.define do
  factory :mollie_payment_method, class: Spree::PaymentMethod::Mollie do
    name 'Mollie'
  end
end
