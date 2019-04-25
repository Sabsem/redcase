
# TODO: "Combos" is not business case specific name, we need to come up with a
#       better one. As this controller generates output for reports, it could be
#       ReportController which would had two separate methods to generate two
#       different kind of data (for the download button and the combo controls).
class Redcase::CombosController < ApplicationController

	unloadable
	helper RedcaseHelper
	before_filter :find_project, :authorize, :except=> [:show]

	def index
		@environment =
			if params[:environment_id]
				ExecutionEnvironment.find(params[:environment_id])
			else
				ExecutionEnvironment.get_default_for_project(@project)
			end
		@version =
			if params[:version_id]
				Version.find(params[:version_id])
			else
				Version.order('created_on desc').find_by_project_id(@project.id)
			end
		@root_execution_suite =
			if params[:suite_id]
				ExecutionSuite.find_by_id(params[:suite_id])
			else
				ExecutionSuite.get_root_for_project(@project)
			end
		# TODO: Looks like two different partial views, should be separated.
		if params[:button]
			render :partial => 'redcase/report_download_button'
		else
			render :partial => 'redcase/report_combos'
		end
	end

	def show
		puts "in combo show"
		@project = Project.find(params[:project_id] || params[:id])
		@environment =
			if params[:environment_id]
				ExecutionEnvironment.find(params[:environment_id])
			else
				ExecutionEnvironment.get_default_for_project(@project)
			end
		@version =
			if params[:version_id]
				Version.find(params[:version_id])
			else
				Version.order('created_on desc').find_by_project_id(@project.id)
			end
		@root_execution_suite =
			if params[:suite_id]
				ExecutionSuite.find_by_id(params[:suite_id])
			else
				ExecutionSuite.get_root_for_project(@project)
			end

		sql = %{
			Select t.id As test_case_id, i.id As issue_id
			From execution_suite_test_case et 
			Left Outer Join execution_suites e on et.execution_suite_id=e.id 
			Left Outer Join test_cases t on et.test_case_id= t.id
			Left Outer Join issues i On t.issue_id=i.id 
			Where et.id = #{params[:suite_id]};
		}

		sql = %{
			Select
			From execution_journals ej 
			Left Outer Join test_cases tc on ej.test_case_id= tc.id 
			Left Outer Join execution_suite_test_case et On et.test_case_id=tc.id
			Left Outer Join execution_results er On ej.result_id = er.id
			Left Outer Join versions v On ej.version_id = v.id
			Left Outer Join execution_environments ee On ej.environment_id=ee.id
			Where
		}
		#test_cases = ActiveRecord::Base.connection.execute(sql)
		test_cases = ExecutionSuite.get_results(
				@environment,
				@version,
				params[:suite_id].to_i,
				@project.id
			)
		#puts test_cases.inspect	

		render plain: 'plain text'
	end

	private

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id] || params[:id])
	end

end

