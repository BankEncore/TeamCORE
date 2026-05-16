# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  namespace :admin do
    root "dashboard#show"
    resource :agency_context, only: %i[show update], controller: "agency_context"

    resources :agencies, only: %i[index show edit update]
    resources :departments, only: %i[index show new create edit update]
    resources :locations, only: %i[index show new create edit update]
    resources :teams, only: %i[index show new create edit update]

    resources :parties, only: %i[index show edit update] do
      resources :party_contact_methods, only: %i[new create edit update]
      resources :party_relationships, only: %i[index new create edit update] do
        member do
          post :promote
        end
      end
    end
    get "parties/new/person", to: "parties#new_person", as: :new_person_party
    post "parties/person", to: "parties#create_person", as: :person_parties
    get "parties/new/organization", to: "parties#new_organization", as: :new_organization_party
    post "parties/organization", to: "parties#create_organization", as: :organization_parties

    resources :team_members, only: %i[index show new create edit update] do
      resource :team360, only: %i[show], controller: "team360"
    end
    resources :pay_periods
    resources :compensation_plans
    resources :contractor_settlement_runs, only: %i[index show new create] do
      member do
        post :finalize
        post :compose_line
        post :void
        post :mark_paid
      end
    end
    resources :engagements, only: %i[index show new create edit update] do
      resources :placements, controller: "engagement_placements", only: %i[index show new create edit update]
      resources :supervision_assignments, controller: "engagement_supervisions", only: %i[index show new create edit update]
      scope module: :engagements do
        resources :compensation_plan_assignments, path: "compensation_assignments", except: %i[show]
        resources :revenue_inputs do
          member { post :calculate_commission }
          collection { post :import_csv }
        end
        resources :commission_calculations, only: [ :index ] do
          member do
            post :finalize
          end
        end
        resources :contractor_charges do
          resources :contractor_charge_waivers, path: "waivers", only: %i[new create]
        end
      end
    end

    resources :document_types
    resources :document_requirements, except: %i[show destroy]
    resources :document_records do
      member do
        post :verify
        post :reject
        post :void
      end
    end
    resources :document_alerts, only: %i[index]
    resources :document_reviews, only: %i[index]

    namespace :reports do
      root to: "home#show"
      resources :team_members, only: %i[index]
      resources :engagements, only: %i[index]
      resources :document_compliance, only: %i[index]
      resources :contractor_documentation, only: %i[index]
      resources :subcontractors, only: %i[index]
    end
  end

  root "home#index"
end
