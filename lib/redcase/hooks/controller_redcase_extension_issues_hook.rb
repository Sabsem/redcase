module Redcase
	module Hooks
		class ControllerRedcaseExtensionIssuesHook < Redmine::Hook::ViewListener
			def controller_issues_edit_after_save(context={})
				# puts "in issue hook"
				# puts context[:issue]
				# puts context[:journal].inspect
				

			end


		end
	end
end