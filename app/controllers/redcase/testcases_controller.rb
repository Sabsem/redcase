
class Redcase::TestcasesController < ApplicationController

	unloadable
	before_filter :find_project, :authorize

	def index
		# TODO: What if there is none? r.issue_from_id, r.issue_to_id, t.name
		puts "in testcases index"
		sql = %{
				Select r.issue_from_id, r.issue_to_id, t.name, i.subject, s.name As status  
				From issue_relations r
				Left Outer Join issues i On r.issue_to_id=i.id
				Left Outer Join trackers t On i.tracker_id=t.id
				Left Outer Join issue_statuses s on i.status_id=s.id
				Where r.issue_from_id=#{params[:object_id]};
			}
		test_case = TestCase.where({ issue_id: params[:object_id] }).first
		relation_case = IssueRelation.where({issue_from_id: test_case.issue_id}, {relation_type: 'relates' })
		relation_join = ActiveRecord::Base.connection.exec_query(sql)
		result = {}
		curr_user = {}
		curr_user[:id]=User.current.id
		thename = User.current.firstname + " " +User.current.lastname
		curr_user[:name]=thename
		result[:test_casej]=test_case.to_json(view_context)
		result[:relation_casej]=relation_join
		result[:project_j]=@project
		result[:current_userj]=curr_user
		render :json => result
	end

	def copy
		destination_project = Project.find(params[:dest_project])
		unless User.current.allowed_to?(:add_issues, destination_project)
			raise ::Unauthorized
		end
		# TODO: What if there is none?
		test_case = TestCase.where({ issue_id: params[:id] }).first
		test_case.copy_to(destination_project)
		render :json => { :success => true }
	end

	def update
		# TODO: What if there is none?\
		logger.info "in testcases update"
		test_case = TestCase.where({ issue_id: params[:id] }).first
		if test_case.nil?
			success = false
		else
			unless params[:parent_id].nil?
				test_case.test_suite = TestSuite.find(params[:parent_id])
			end
			unless (params[:source_exec_id].nil? || params[:dest_exec_id].nil?)
				success = test_case.change_execution_suite?(
					params[:source_exec_id], params[:dest_exec_id]
				)
			end
			unless (!params[:source_exec_id].nil? || params[:dest_exec_id].nil?)
				success = test_case.add_to_execution_suite?(
					params[:dest_exec_id]
				)
			end
			unless params[:remove_from_exec_id].nil?
				test_case.remove_from_execution_suite(
					params[:remove_from_exec_id]
				)
			end
			unless params[:obsolesce].nil?
				test_case.test_suite = TestSuite.get_obsolete(@project)
			end
		end
		if params[:contextHook]=='yes'
			logger.info "in context"
			test_case.save
			for i in 0..params[:add_id].count-1 do
				if params[:add_id][i] != params[:id]
					test_case = TestCase.where({issue_id: params[:add_id][i]}).first 
					test_case.test_suite = TestSuite.find(params[:parent_id])
					test_case.save
				end
			end
			redirect_to project_issues_path(params[:project_id])
		elsif params[:result].nil?
			test_case.save
			render :json => {:success => success}

		else
			execute(test_case)
		end
	end


	private

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

	def execute(test_case)
		logger.info "in testcases execute"
		version = Version.find_by_name_and_project_id(
			params[:version],
			@project.id
		)
		comment = params[:comment].blank? ? nil : params[:comment]
		result = ExecutionResult.find_by_name(params[:result])
		environment = ExecutionEnvironment.find(params[:envs])
		ExecutionJournal.create(
			version: version,
			comment: comment,
			test_case: test_case,
			result: result,
			executor: User.current,
			environment: environment
		)
		theIss = Issue.find(params[:id])
		theIss.init_journal(User.current)
		theIss.current_journal[:notes]=comment
		theIss.save
		render :json => ExecutionJournal
			.order('created_on desc')
			.where({ test_case_id: test_case.id })
			.collect { |ej| ej.to_json }
	end

end

