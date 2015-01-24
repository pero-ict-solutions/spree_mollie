class AddPaymentIdToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :mollie_transaction_id, :string
    add_index :spree_orders, :mollie_transaction_id
  end
end
