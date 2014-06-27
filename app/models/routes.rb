ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  map.root :controller => 'home'

  #TODO Remove this
  #map.resource :account, :controller => "users"
  
  map.resource :user_session
  map.resource :support, :controller => :support, :only => :none, :collection => {:contact_us => :get, :send_contact_us_email => :post, :mobile_tribe_description => :get, :mobile_tribe_client => :get}
  map.resource :search, :controller => 'search', :only => :index, :collection => {:users => :get, :companies => :get}
  map.resources :users, :member => {:contacts => :get, :friends => :get, :friendship_request => :get, :friendship_delete => :get, :remove_mt_association => :put} do |user|
    user.resources :companies, :collection => {:application => :get}
    user.resources :dashboard, :controller => "dashboard", :collection => {:ondeego_login_failed => :get}
    user.resources :employers, :member => {:accept => :get, :reject => :get}
    user.resources :friendships, :member => {:accept => :get, :reject => :get},
                                 :collection => {:accept_all => :post, :reject_all => :post, :resend_all => :post,
                                                 :destroy_all => :post, :incoming_requests => :get,
                                                 :outcoming_requests => :get, :rejected_outcoming_requests => :get}
    user.resource  :ondeego, :controller => "ondeego", :only => :none, :collection => {:company_create => :get, :employee_create => :get, :login => :get}
    user.resource  :sogo, :controller => "sogo", :only => :none, :collection => {:login => :get}
  end
  map.resources :companies, :member => {:profile => :get} do |company|
    company.resources :employees, :member => {:invite => :get, :edit_by_employee => :get, :update_by_employee => :put, :sogo_connect => :get}, :collection => {:invite_all => :post, :destroy_all => :post}
    company.resources :departments, :member => {:edit_by_department => :get, :update_by_department => :put},  :collection => {:destroy_all => :post}
  end
  map.resources :employees, :collection => {:people => :get, :new_recruit => :get, :recruit => :post, :invitation => :get, :company_department => :get, :check_email_name => :get}
  map.resources :password_resets, :only => [ :new, :create, :edit, :update ]
  # See how all your routes lay out with "rake routes"

  map.namespace :api do |api|
    api.namespace :v1 do |v1|
      v1.resources :users, :member => {:contacts => :get, :friends => :get}
    end
    api.namespace :v2 do |v2|
      v2.resources :companies, :only => [:index], :collection => {:create_success => :get, :create_fail => :get}
      v2.resources :employees, :only => [:index], :collection => {:create_success => :get, :create_fail => :get,
                                                                  :login_fail => :get}
      v2.resources :users, :collection => {:contacts => :get, :friends => :get}
    end
  end

  map.namespace :admin do |admin|
    admin.resources :users, :member => {:block => :put, :unblock => :put, :info => :get}
    admin.resources :companies, :member => {:employees => :get, :invite => :get}
    admin.resources :audits, :except => [:new, :create], :member => {:association_audits => :get, :send_emails => :post, :new_email => :get}
    admin.resources :help_urls
  end

  map.logout '/logout', :controller => 'user_sessions', :action => 'destroy'
  map.login '/login', :controller => 'user_sessions', :action => 'new'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.invitation '/invitation', :controller => 'employees', :action => 'invitation'

  map.admin '/admin', :controller => 'admin/users', :action => 'index'

  #map.contacts '/contacts/:id', :controller => 'users', :action => 'contacts', :method => :any
  #map.contacts '/contacts/:id.:format', :controller => 'users', :action => 'contacts', :method => :any


  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
