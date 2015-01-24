FactoryGirl.define do
  factory :mollie_payment, class: Spree::Payment do
    amount 45.55
    association(:payment_method, factory: :mollie_payment_method)
    state 'checkout'
    order

    factory :completed_mollie_payment do
      state 'completed'
    end
  end
end
