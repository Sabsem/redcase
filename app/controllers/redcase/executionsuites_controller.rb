
class Redcase::ExecutionsuitesController < ApplicationController

	unloadable
	before_filter :find_project, :authorize

	def index
		puts "in suites index"
		if params[:get_results].nil?
			puts "in suites index if"
			@list2 = ExecutionSuite.find_by_project_id(@project.id)
			@version = Version
				.order('created_on desc')
				.find_by_project_id(@project.id)
			render :partial => 'redcase/execution_list'
		else
			puts "in suites index else"
			@environment = ExecutionEnvironment.find(params[:environment_id])
			@version = Version.find(params[:version_id])
			@root_execution_suite = ExecutionSuite.find_by_id(params[:suite_id])
			@results = ExecutionSuite.get_results(
				@environment,
				@version,
				params[:suite_id].to_i,
				@project.id
			)
			puts "after first results"
			#puts @results.inspect
			#exec_result = ExecutionResult.all
			failID= nil
			failArr = []
			@results.each do |er|
				#puts "iterate"
				#puts er.inspect
				#puts er.result.name
				if (er.result.name=="Failed")
					failArr.push(er.test_case.issue.id)
				end
			end
			puts "after iterate"
			relatedQueryStr = ""
			failArr.each do |f|
				#puts "in failarr iterate"
				if relatedQueryStr != ""
					relatedQueryStr += ", "
				end
				relatedQueryStr += f.to_s
			end
			puts relatedQueryStr
			puts "after string creation"

			sql = %{
				Select r.issue_from_id, r.issue_to_id, t.name, i.subject, s.name As status  
				From issue_relations r
				Left Outer Join issues i On r.issue_to_id=i.id
				Left Outer Join trackers t On i.tracker_id=t.id
				Left Outer Join issue_statuses s on i.status_id=s.id
				Where r.issue_from_id In (#{relatedQueryStr});
			}
			begin
				@relation_join = ActiveRecord::Base.connection.execute(sql)
			rescue => e 
				@relation_join = nil
			end
			# @relation_join.each do |x|
			# 	puts x.inspect
			# end
			puts "after query"
			@results = ExecutionSuite.get_results(
				@environment,
				@version,
				params[:suite_id].to_i,
				@project.id
			)
			render :partial => 'redcase/report_results'
		end
	end

	def show
		unless params[:version].nil?
			version = Version.find_by_name_and_project_id(
				params[:version],
				@project.id
			)
		end
		unless params[:environment].nil?
			environment = ExecutionEnvironment.find(params[:environment])	
		end
		render :json => ExecutionSuite.find(params[:id]).to_json(
			view_context, version, environment
		)
	end

	def create
		execution_suite =
			# TODO: Compute project id first, then user ExecutionSuite.create
			#       just once.
			if params[:parent_id].nil?
				ExecutionSuite.create(
					:name => params[:name],
					:project_id => @project.id
				)
			else
				ExecutionSuite.create(
					:name => params[:name],
					:parent_id => params[:parent_id]
				)
			end
		render :json => execution_suite.to_json(view_context)
	end

	def update
		execution_suite = ExecutionSuite.find(params[:id])
		execution_suite.parent = ExecutionSuite
			.find(params[:parent_id]) unless params[:parent_id].nil?
		execution_suite.name = params[:new_name] unless params[:new_name].nil?
		execution_suite.save
		render :json => { :success => true }
	end

	def destroy
		ExecutionSuite.destroy(params[:id])
		render :json => { :success => true }
	end

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

end

