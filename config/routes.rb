Rails.application.routes.draw do
  resources :bacons

  root to: 'bacons#stats'
  get 'did_launch' => 'bacons#did_launch'
end
