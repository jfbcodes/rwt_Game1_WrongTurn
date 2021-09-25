Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # ACCOUNT ACTIONS
  post '/participants/update-account' => 'participants#update_account'
  post '/participants/signup-guest' => 'participants#signup_guest'

  # AUTH
  post '/participants/create' => 'participants#create'
  post '/participants/login' => 'participants#login'
  post '/participants/create-with-membership' => 'participants#create_with_membership'
  post '/participants/resend-phone-confirmation-code' => 'participants#resend_phone_confirmation_code'
  post '/participants/request-auth-code' => 'participants#request_auth_code'
  post '/participants/verify-phone-number' => 'participants#verify_phone_number'


end
