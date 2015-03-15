Rails.application.routes.draw do
  resources :folders, :id => /.*/ do
    resources :messages
  end
end
