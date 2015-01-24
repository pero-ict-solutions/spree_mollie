FactoryGirl.define do
  factory :order_paid_by_mollie, parent: :completed_order_with_totals do
    after(:create) do |order|
      create(:completed_mollie_payment, amount: order.total, order: order)
    end
  end
end
