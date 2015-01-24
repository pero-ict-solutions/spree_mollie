#spec/models/spree/payment_method/mollie_spec.rb

require 'spec_helper'

describe Spree::PaymentMethod::Mollie do

  describe "set api_key in preferences" do
    it "can save an api_key attribute" do
      mollie = Spree::PaymentMethod::Mollie.new({name: "Mollie"})
      mollie.set_preference(:api_key, "my-awesome-key")
      mollie.save!
      expect(mollie.get_preference(:api_key)).to eql "my-awesome-key"
    end
  end
end


