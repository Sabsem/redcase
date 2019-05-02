
require 'redmine'
require 'issue_patch'
require 'project_patch'
require 'version_patch'
require 'user_patch'
require 'redcase_override'
require 'redcase/hooks/view_redcase_extension_context_menu_hook'
#require 'redcase/hooks/controller_redcase_extension_issues_hook'
Redmine::Plugin.register :redcase do

	name 'Redcase'
	description 'Test cases management plugin for Redmine'
	author 'Bugzinga Team'
	version '1.0'

        project_module :redcase do	
	   permission :view_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index
		],
		'redcase/testsuites' => [
			:index
		],
		'redcase/testcases' => [
			:index
		],
		'redcase/executionjournals' => [
			:index
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index,
			:show
		],
		'redcase/graph' => [
			:show
		],
		'redcase/combos' => [
			:index
		]
	   }

	   permission :edit_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index,
			:update,
			:destroy,
			:create
		],
		'redcase/testsuites' => [
			:index,
			:update,
			:destroy,
			:create
		],
		'redcase/testcases' => [
			:index,
			:update,
			:destroy,
			:copy
		],
		'redcase/executionjournals' => [
			:index
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index,
			:update,
			:destroy,
			:create,
			:show
		],
		'redcase/graph' => [
			:show
		],
		'redcase/combos' => [
			:index
		]
	   }

	   permission :execute_test_cases, {
		:redcase => [
			:index,
			:get_attachment_urls
		],
		'redcase/environments' => [
			:index
		],
		'redcase/testsuites' => [
			:index
		],
		'redcase/testcases' => [
			:index,
			:update
		],
		'redcase/executionjournals' => [
			:index
		],
		'redcase/export' => [
			:index
		],
		'redcase/executionsuites' => [
			:index
		]
	   }
	end

	menu :project_menu,
		:redcase, {
			:controller => 'redcase',
			:action => 'index'
		}, {
			:if => proc { |p|
				can_view = User.current.allowed_to?(:view_test_cases, p)
				can_edit = User.current.allowed_to?(:edit_test_cases, p)
				can_view || can_edit
			},
			:caption => :label_redcase_test_case,
			:after => :new_issue
		}

	settings partial: 'settings/redcase', default: {:testcase_tracker_id => '2', :testcase_new_status_id => '1', :testcase_doing_status_id => '2', :testcase_close_status_id => '5'}

	Rails.configuration.to_prepare do
		Issue.send :include, IssuePatch
		Project.send :include, ProjectPatch
		Version.send :include, VersionPatch
		User.send :include, UserPatch
	end

end

