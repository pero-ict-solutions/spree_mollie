FactoryGirl.define do
  factory :mollie_payment, class: Spree::Payment do
    amount 45.55
    association(:payment_method, factory: :mollie_payment_method, preferences: { api_key: 'test_pw5ZHNihuiFKefzBwZVwAdKXt5C4Xe' })
    state 'checkout'
    order

    factory :completed_mollie_payment do
      state 'completed'
    end

    factory :pending_mollie_payment do
      state 'pending'
    end
  end
end
