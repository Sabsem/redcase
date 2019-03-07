module Redcase
	module Hooks
		class ControllerRedcaseExtensionIssuesHook < Redmine::Hook::ViewListener
			def controller_issues_edit_after_save(context={})
				puts "in issue hook"
				puts "issue"
				puts params[:issue]
				puts "journal"
				puts params[:journal]

			end


		end
	end
end