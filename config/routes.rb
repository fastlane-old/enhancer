Rails.application.routes.draw do
  resources :bacons
  resources :entries

  root to: 'entries#stats'
  get 'did_launch' => 'bacons#did_launch'
end
