Spree::Core::Engine.routes.draw do
  post '/mollie/notify', to: 'mollie#notify', as: 'notify_mollie'

  namespace :admin do
    resources :orders, :only => [] do
      resources :payments, :only => [] do
        member do
          get 'mollie_refund'
        end
      end
    end
  end
end