
class Redcase::ExecutionjournalsController < ApplicationController

	unloadable
	before_filter :find_project, :authorize, :except=>:update

	def index
		journals =
			if !params[:issue_id].nil?
				ExecutionJournal.find_by_issue_id(params[:issue_id])
			else
				ExecutionJournal.order('created_on desc')
			end

		render :json => journals.map(&:to_json)
	end

	def update
		@project = Project.find(params[:project_id])
		formDigest = params[:attachments]["1"]["token"]
		digestChar = formDigest.slice!(0)
		while digestChar != '.'
			digestChar = formDigest.slice!(0)
		end
		sql = %{
			Select * 
			From attachments a
			Where a.filename='#{params[:attachments]["1"]["filename"]}'
			And a.digest = '#{formDigest}'
			And a.container_id IS NULL
			And a.container_type IS NULL
			Order By a.id desc;
		}
		attachEntry = ActiveRecord::Base.connection.execute(sql)
		theAttach=Attachment.find_by(id:attachEntry[0]["id"])
		theAttach.container_id=params[:id]
		theAttach.container_type = "Issue"
		theAttach.save
		redirect_to "/projects/1/redcase?tab=Execution" and return
	end

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

end

