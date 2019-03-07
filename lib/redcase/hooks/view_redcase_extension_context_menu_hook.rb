module Redcase
	module Hooks
		class ViewRedcaseExtensionContextMenuHook < Redmine::Hook::ViewListener
			
			def view_issues_context_menu_start(context={})
				sql = %{
					Select *
					From trackers
					Where id=#{context[:issues][0][:tracker_id]}
				}
				tracks = ActiveRecord::Base.connection.execute(sql)
				if tracks[0]["name"] == "Test case"
					puts context[:issues][0].inspect
					listItems = ""
					tsuites=Array.new()
					testsuite = TestSuite.find_by_project_id(context[:issues][0][:project_id]);
					tsuites.push(testsuite)	
					tsuites.each do |item|
						if item !=nil
							sql = %{
								Select *
								From test_suites
								Where parent_id=#{item["id"]};
							}
							testsuite= ActiveRecord::Base.connection.execute(sql)
							testsuite.each do |child|
								tsuites.push(child)
							end

						end
					end
					tsuites.each do |item|
						pathurl = project_redcase_testcase_path(context[:issues][0][:project_id], context[:issues][0][:id], :parent_id=>item["id"], :source_exec_id=>nil, :dest_exec_id=>nil, :remove_from_exec_id=>nil, :obsolesce=>nil, :contextHook=>'yes')
						listItems=listItems+"<li><a class rel='nofollow' data-method='patch' href='#{pathurl}'>#{item["name"]}</a></li>"
					end

					return %{
						<li class="folder">
							<a href="#" class="submenu">Add to Test Suite</a>
							<ul>
								#{listItems}	
							</ul>
						</li>
					}
				end
				return
			end

		end

	end
end

