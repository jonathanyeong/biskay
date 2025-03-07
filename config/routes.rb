Rails.application.routes.draw do
  resource :session
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  resources :skeets do
    post "share", on: :collection
    get "search_actors", on: :collection
  end
  mount MissionControl::Jobs::Engine, at: "/jobs"
  root "skeets#index"
end

# Adding mission control jobs
# bin/rails credentials:edit <- Gen creds file
# Or bin/rails mission_control:jobs:authentication:configure
