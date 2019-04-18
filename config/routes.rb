
resources :projects do
	namespace :redcase do
		resources :environments, only: [:index, :create, :update, :destroy]
		resources :testsuites, only: [:index, :create, :update, :destroy]
		resources :testcases, only: [:index, :update] do
			post 'copy', on: :member
			match 'bulk_edit', :via => [:get, :post]
		end
		resources :executionsuites, only: [:index, :update, :create, :destroy, :show]
		resources :executionjournals, only: [:index,:edit,:update]
		resources :export, only: [:index]
		resources :graph, only: [:show]
		resources :combos, only: [:index, :show]
	end
end

get 'projects/:id/redcase', :to => 'redcase#index'
get 'projects/:id/redcase/get_attachment_urls', :to => 'redcase#get_attachment_urls'

#match "/project/:project_id/redcase/:id/:parent_id/:source_exec_id/:dest_exec_id/:remove_from_exec_id/:obsolesce", :controller=> "testcases", :action=> "update", via: :all