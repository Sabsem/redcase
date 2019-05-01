
class Redcase::ExecutionjournalsController < ApplicationController

	unloadable
	before_filter :find_project, :authorize, :except=>[:update, :edit]

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
		if (params[:extension_form]=="extension")
			logger.info "in journo update if"
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
			logger.info "After attachment lookup"
			attachEntry.each do |x|
				logger.info x.inspect
			end
			theAttach=Attachment.find_by(id:attachEntry[0]["id"])
			theAttach.container_id=params[:id]
			theAttach.container_type = "Issue"
			theAttach.save
			redirect_to "/projects/#{params[:project_id]}/redcase?tab=Execution" and return
		elsif (params[:extension_form]=="editing")
			logger.info "in journo update else (editing)"
			theDate = params[:extension_date]
			theDateDay = theDate.slice!(0..1).to_i
			theDate.slice!(0)
			theDateMonth = theDate.slice!(0..1).to_i
			theDate.slice!(0)
			theDateYear =theDate.slice!(0..3).to_i
			theDate.slice!(0)
			theDateHour =theDate.slice!(0..1).to_i
			theDate.slice!(0)
			theDateMinute =theDate.slice!(0..1).to_i
			theDate.slice!(0)
			theDateSeconds = theDate.slice!(0..1).to_i
			dbDate = DateTime.new(theDateYear,theDateMonth,theDateDay,theDateHour,theDateMinute,theDateSeconds)
			dbDate= dbDate.in_time_zone("Pacific Time (US & Canada)")
			dbDateUpper = dbDate + 2.seconds
			formattedDate = ""+dbDate.year.to_s+"-"+dbDate.month.to_s.rjust(2, "0")+"-"+dbDate.day.to_s.rjust(2, "0")+" "+dbDate.hour.to_s.rjust(2, "0")+":"+dbDate.min.to_s.rjust(2, "0")+":"+dbDate.sec.to_s.rjust(2, "0")
			formattedDateUpper =  ""+dbDateUpper.year.to_s+"-"+dbDateUpper.month.to_s.rjust(2, "0")+"-"+dbDateUpper.day.to_s.rjust(2, "0")+" "+dbDateUpper.hour.to_s.rjust(2, "0")+":"+dbDateUpper.min.to_s.rjust(2, "0")+":"+dbDateUpper.sec.to_s.rjust(2, "0")
			sql = %{
				Select *
				From execution_journals e 
				Where e.created_on >= '#{formattedDate}' And e.created_on < '#{formattedDateUpper}'
				And e.executor_id=#{params[:extension_user_id]};
			}
			toEditEntry = ActiveRecord::Base.connection.execute(sql)
			logger.info "after journo lookup"
			logger.info toEditEntry.inspect
			if toEditEntry.count == 1
				theJournalResults = ExecutionResult.where("name=?", params[:results_edit])
				editedResult= theJournalResults[0][:id]
				editedComment= params[:exec_comment_edit]
				toEditJournal = ExecutionJournal.find(toEditEntry[0]["id"]);
				toEditJournal.result_id = editedResult
				toEditJournal.comment = editedComment
				toEditJournal.save
				sql = %{
					Select *
					From journals j
					Where j.created_on >= '#{formattedDate}' And j.created_on < '#{formattedDateUpper}'
					And j.user_id=#{params[:extension_user_id]};
				}
				toEditIssueJournal = ActiveRecord::Base.connection.execute(sql)
				logger.info "after second journo lookup"
				logger.info toEditIJournal.inspect
				if toEditIssueJournal.count==1
					toEditIJournal = Journal.find(toEditIssueJournal[0]["id"])
					toEditIJournal.notes = editedComment
					toEditIJournal.save
				elsif toEditIssueJournal.count==0
					#TODO the journal couldn't be found
					# theIss = Issue.find(params[:id])
					# theIss.init_journal[:notes]=editedComment
					# theIss.save
				else
					#TODO more than one journal with the time stamp

				end

			else
				#TODO more than one exec journal with the time stamp
			end
			redirect_to "/projects/#{params[:project_id]}/redcase?tab=Execution" and return
		end
	end

	def edit
		#journalResults = ExecutionResult.all
		# result = {}
		# result[:all_results]=journalResults
		render :json => journalResults
		#redirect_to"/projects/1/redcase?tab=Execution" and return

	end

	# TODO: Extract to a base controller.
	def find_project
		@project = Project.find(params[:project_id])
	end

end

