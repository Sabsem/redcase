
var RedcaseExecutionTree = function($) {

	var tree;

	var currentIssueId;

	this.refresh = function() {
		if (tree) {
			tree.refresh();
		}
	};

	this.execute = function() {
		var issueId = currentIssueId;
		if (!issueId) {
			// TODO: Log something.
			return;
		}
		var selectedNode = tree.get_node(tree.get_selected(true)[0], true);
		var result = $('#results').val();
		var apiParams = $.extend(
			{},
			Redcase.api.testCase.update(issueId), {
				params: {
					version: $('#version').val(),
					result: result,
					envs: $('#environments').val(),
					comment: $('#exec-comment').val()
				},
				success: function(data) {
					$('#all-results-d').toggle(data.length > 0);
					$('#all-results').html(getHistory(data));
					tree.set_icon(
						selectedNode, (
							'testcase-result-icon-'
							+ result.replace(/\s*/g, '')
						)
					);
					selectNextNode();
					$('#exec-comment').val('');
					// TODO: When a user executes a test case, the results
					//       are getting updated and we need to refresh
					//       the Report tab as well. Triggering combo
					//       controls' changes might be not the best
					//       solution, but at least it seems to fix the
					//       issue with updates.
					Redcase.combos.refresh();
				},
				errorMessage: 'Execution failed'
			}
		);
		Redcase.api.apiCall(apiParams);
	};

	var build = function(params) {
		tree = $('#execution_test_cases_tree_id').jstree({
			core: {
				check_callback: function() {
					return false;
				},
				data: {
					type: 'GET',
					url: function() {
						return Redcase.api.context
							+ Redcase.api.executionSuite.show(
								$('#list2_id').val()
							).method
					},
					data: function() {
						return {
							version: $('#version').val(),
							environment: $('#environments').val()
						}
					}
				},
				multiple: false
			}
		});
		tree.on('select_node.jstree', selectionChange);
		tree = $.jstree.reference(tree);
	};

	var selectionChange = function(event, params) {
		var node = params.node;
		var edit = $('#test-case-edit');
		edit.hide();
		$('#all-results-d').hide();
		if (node.original.type == 'case') {
			var apiParms = $.extend(
				{},
				Redcase.api.testCase.index(), {
					params: {
						"object_id": node.original.issue_id
					},
					success: function(data) {
						console.log("selection change");
						console.log(data);
						currentUser = data.current_userj;
						currentIssueId = data.test_casej.issue_id;
						$('#exec_descr_id').toggle(
							data.test_casej.desc !== undefined
						);
						var desc = $('#test-case-desc');
						var subj = $('#test-case-subj');
						var relat= $('#test-case-related');
						var attachFormUri = "redcase/executionjournals/"+currentIssueId;
						document.getElementById("extensionAttachForm").action = attachFormUri;
						var relateHtml="";
						var issueUrl = getIssueUrl(data.test_casej.issue_id);
						subj.html(
							'<a href="'
							+ issueUrl
							+ '">'
							+ data.test_casej.text
							+ '</a>'
						);
						desc.html(data.test_casej.desc);
						relateHtml = relateHtml + '<p><b>Related Issues:</b></p>';
						relateHtml= relateHtml + '<table id="executionrelatedissues" class="list issues odd-even">' + '<tbody>';
						jQuery.each(data.relation_casej, function(){
							var testIssueUrl= getIssueUrl(this.issue_to_id);
							relateHtml=relateHtml+ '<tr class="executionissues"><td style="width: 25%; border-style: hidden"><a href='
							+ testIssueUrl
							+ '">'
							+ this.name
							+ '#' + this.issue_to_id
							+ '</a></td>'
							+ '<td style="width: 50%; border-style: hidden">'+ this.subject +'</td>'
							+ '<td style="width: 25%; border-style: hidden">'+ this.status + '</td></tr>'

						});
						relateHtml = relateHtml+'</tbody></table>'
						relat.html(relateHtml);						
						edit.show();
						var results = $('#results');
						results.val('Passed');
						var version = $('#version');
						var apiParms = $.extend(
							{},
							Redcase.api.executionJournal.index(), {
								params: {
									"issue_id": node.original.issue_id,
									"version": version.val()
								},
								success: function(data) {
									$('#all-results-d').toggle(
										data.length > 0
									);
									if (data.length > 0) {
										console.log(data);
											//if (currentUser.name==data[i].executor){
										console.log("Before history");
										console.log(currentUser);
										var txt = getHistory(data);
										$('#all-results').html(txt);
									}
								},
								errorMessage: (
									'Unable to get execution results'
								)
							}
						);
						Redcase.api.apiCall(apiParms);
						apiParms = $.extend(
							{},
							Redcase.api.core.getAttachmentURLs(), {
								params: {
									"issue_id": node.original.issue_id
								},
								success: function(data) {
									console.log('In second api function\n');
									console.log(data);
									$('#test-case-attach').toggle(
										data.length > 0
									);
									if (data.length > 0) {
										var txt = "";
										for (i = 0; i < data.length; i++) {
											txt += "<a href='"
												+ data[i].url
												+ "' target='_blank'>"
												+ "<img src="
												+ '"'
												+ "/images/attachment.png"
												+ '"'
												+ "></img>"
												+ data[i].name
												+ "</a><br/>";
										}
										$('#test-case-attach').html(txt);
									}
								},
								errorMessage: "Getting attachments failed"
							}
						);
						Redcase.api.apiCall(apiParms);
					},
					errorMessage: (
						"Information about test case '"
						+ node.text
						+ "' can't be obtained"
					)
				}
			);
			Redcase.api.apiCall(apiParms);
		}
	};

	var getHistory = function(data) {
		console.log("gethistory");
		console.log(data);
		console.log("current user");
		console.log(currentUser);
		var unique = {};
		var txt = "<table id='redcase-history-table' class='redcase-row' width='100%'>"
			+ "<tr style='font-weight: bold; background-color: #eeeeee'>"
			+ "<td>date (UTC)</td>"
			+ "<td>result</td>"
			+ "<td>comments</td>"
			+ "<td>executor</td>"
			+ "<td>environment</td>"
			+ "<td>version</td>"
			+ "</tr>";
		for (var i = 0; i < data.length; i++) {
			var color;
			switch (data[i].result) {
				case "Passed":
					color = "#bbff88";
					break;
				case "Failed":
					color = "#ffbbbb";
					break;
				case "Not Available":
					color = "#dddddd";
					break;
				case "Blocked":
					color = "#ccccff";
					break;
				default:
					color = "#ffffff";
					break;
			}
			var notFirst = (unique[data[i].environment + data[i].version]);
			txt += "<tr"
				+ (notFirst
					? " style='background-color: " + color + "'"
					: (
						" style='background-color: "
						+ color
						+ "; font-weight: bold'"
					)
				)
				+ ">";
			txt += "<td>" + data[i].created_on + "</td>";
			txt += "<td>" + data[i].result + "</td>";
			txt += "<td><span id='comment-history-"+i+"'>" + data[i].comment+"</span>";
			if(currentUser.name == data[i].executor){
				txt += " " + "<a class='icon-only icon-edit' href='#' onclick='execJournalEditor("+i+");return false;'>ToEdit</a>";
			}
			txt += "</td>";
			txt += "<td>" + data[i].executor + "</td>";
			txt += "<td>" + data[i].environment + "</td>";
			txt += "<td>" + data[i].version + "</td>";
			txt += "</tr>";
			if (!notFirst) {
				unique[data[i].environment + data[i].version] = 1;
			}
		}
		txt += "</table>";
		return txt;
	};

	var selectNextNode = function() {
		var nextNode = tree.get_node(
			tree.get_next_dom(tree.get_selected(true)[0], false)
		);
		while (nextNode && (nextNode.original.type !== 'case')) {
			if (nextNode.children.length > 0) {
				tree.open_node(nextNode);
			}
			nextNode = tree.get_node(tree.get_next_dom(nextNode, false));
		}
		if (!nextNode) {
			return;
		}
		tree.deselect_all();
		tree.select_node(nextNode);
	};

	(function() {
		build();
		$('#execution_settings_id').on(
			'change',
			'select',
			function() {
				tree.refresh();
			}
		);
	})();

};

jQuery2(function($) {
	if (typeof(Redcase) === 'undefined') {
		Redcase = {};
	}
	if (Redcase.executionTree) {
		return;
	}
	Redcase.executionTree = new RedcaseExecutionTree($);
});

function execJournalEditor(journalnum){
	//var x = document.getElementById("executionjournal_dropdown").value;
	journalEditorDisplay("block");
	console.log ("selected: "+journalnum);
	var theSelectedRow = journalnum +1 ;
	var theTable = document.getElementById("redcase-history-table");
	console.log(theTable);
	var theRow = theTable.rows[theSelectedRow];
	console.log(theRow);
	console.log(theRow.cells[2]);
	var theDivEdit = document.getElementById("executionjournal_edit_date");
	theDivEdit.innerHTML = theRow.cells[0].innerHTML;
	theDivEdit = document.getElementById("extension_date");
	theDivEdit.value = theRow.cells[0].innerHTML;
	theDivEdit = document.getElementById("results_edit");
	theDivEdit.value = theRow.cells[1].innerHTML;
	theDivEdit = document.getElementById("exec_comment_edit");
	theDivEdit.value = document.getElementById("comment-history-"+journalnum).innerHTML;
	theDivEdit = document.getElementById("executionjournal_edit_executor");
	theDivEdit.innerHTML = theRow.cells[3].innerHTML;
	theDivEdit = document.getElementById("executionjournal_edit_environment");
	theDivEdit.innerHTML = theRow.cells[4].innerHTML;
	theDivEdit = document.getElementById("executionjournal_edit_version");
	theDivEdit.innerHTML = theRow.cells[5].innerHTML;


}

function journalEditorDisplay(thedisplay){
	var x = document.getElementById("executionjournalediting");
	x.style.display=thedisplay
}