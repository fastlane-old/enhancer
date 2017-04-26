Rails.application.routes.draw do
  resources :bacons

  root to: 'bacons#stats'
  match 'admin/ok' => 'healthcheck#index', via: :all
  get 'index' => 'bacons#stats'
  post 'did_launch' => 'bacons#did_launch'
  get 'stability' => 'stability#index'
  get 'okrs' => 'stability#okrs'
end
