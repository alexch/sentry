class Main < Erector::Widgets::Page
  needs :checks

  def page_title
    "sentry"
  end

  external :style, <<-STYLE
/* reset.css from http://www.ejeliot.com/blog/85 */
body{padding:0;margin:0;font:13px Arial,Helvetica,Garuda,sans-serif;*font-size:small;*font:x-small;}
h1,h2,h3,h4,h5,h6,ul,li,em,strong,pre,code{padding:0;margin:0;line-height:1em;font-size:100%;font-weight:normal;font-style: normal;}
table{font-size:inherit;font:100%;}
ul{list-style:none;}
img{border:0;}
p{margin:1em 0;}
table { border-spacing: 0px 0px; border-collapse: collapse; }

/* sentry main page */
body{ padding: 1em; }
h1, h2 {
  margin-top: .5em; margin-bottom: .25em; padding: .25em .25em 0;
  border-bottom: 1px solid #222222; background: #EEEEFF;
}
h1 { font-size: 18pt; }
h2 { font-size: 14pt; }

/* styled tables */
td, th { border: 2px solid gray; }
td, th { padding: 2px; }
th { background-color: #EEE; text-align: left; }

/* check table */
td.param, th.param { border: 1px solid gray; }
td.param { width: 100%; }
td.ok { color: green; }
td.failed { color: red; }
td.outcome { font-weight: bold; padding: 2px 4px; }
tr.divider td { border: none; background-color: #ededff; height: 8px; }

/* magic buttons */
div.magic_buttons { float: right; margin: 0 2em 1em; padding: 1em; border: 2px solid blue; background: #EEEEFF; }
div.magic_buttons ul { list-style-type: none; }
div.magic_buttons li { display: inline; margin: .5em; }
div.magic_buttons form { display: inline; }
  STYLE

  external :script, <<-SCRIPT
// Prevents event bubble up or any usage after this is called.
// Thanks to http://projectoverflow.com/questions/128923/html-whats-the-effect-of-adding-return-false-to-an-onclick-event
function cancelEvent(e) {
	if (!e)
		if (window.event) e = window.event;
		else return false;
		if (e.cancelBubble != null) e.cancelBubble = true;
		if (e.stopPropagation) e.stopPropagation();
		if (e.preventDefault) e.preventDefault();
		if (window.event) e.returnValue = false;
		if (e.cancel != null) e.cancel = true;
		return false;
}
nothing = cancelEvent;

/* Log to console, but don't crash if console is absent */
function log(message){
	if (typeof(console) != 'undefined' && typeof(console.log) == 'function'){
		console.log( message );
	}
}
  SCRIPT

  def head_content
    super
    script :src => "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
  end

  def inline_scripts
    super
    # todo: allow :load or :ready as options, in normal ExternalRenderer for :jquery
    rendered_externals(:jquery_ready).each do |external|
      jquery :ready, external.text, external.options
    end
  end

  def nowrap(x)
    span x, :style => "white-space:nowrap;"
  end

  def time(t)
    nowrap t.strftime("%Y-%m-%d")
    text " "
    nowrap t.strftime("%H:%M:%S")
    text " "
    nowrap t.strftime("%Z")
  end


  def check_run_cells(check)
    td { time check.created_at }
    td :class => ["outcome", check.outcome] do
      text check.outcome
    end
    td { text check.reason }
  end

  def params_table(params)
    table :width => "100%" do
      params.each_pair do |key, value|
        tr do
          th(:class => "param") { text key }
          td(:class => "param") { text value }
        end
      end
    end
  end

  def magic_buttons
    div :class => "magic_buttons" do
      h3 "magic buttons:"
      ul do
        if Cron.summon.job.nil?
          li do
            form :action => "/cron", :method => "post" do
              input :type => "hidden", :name => "_method", :value => "put"
              input :type => :submit, :value => "Start Cron"
            end
          end
        else
          li do
            form :action => "/cron", :method => "post" do
              input :type => "hidden", :name => "_method", :value => "delete"
              input :type => :submit, :value => "Stop Cron"
            end
          end
        end
        li do
          form :action => "/work", :method => "get" do
            input :type => :submit, :value => "Work Jobs"
          end
        end
        li do
          form :action => "/sample", :method => "get" do
            input :type => :submit, :value => "Sample"
          end
        end
        li do
          form :action => "/wipe", :method => "get" do
            input :type => :submit, :value => "Wipe DB"
          end
        end
      end
    end
  end

  def checks_table
    h2 "checks", :style => "clear:both;"
    table do
      columns = [
              "type",
              "params",
              "run at",
              "outcome",
              "reason",
              "schedule",
              "next run",
      ]

      tr do
        columns.each do |column|
          th { text column }
        end
      end

      encountered_checkers = []
      @checks.each do |check|
        checker = check.checker
        if check.checker
          next if encountered_checkers.include?(checker)
          encountered_checkers << checker
        end

        tr :class => :divider do
          td :colspan => columns.length
        end

        tr do
          td { text check.class.name }
          td do
            params_table(check.params)
          end
          check_run_cells(check)
          if checker
            td checker.schedule_description
            td do
              time checker.next_run_at
            end
          else
            td "just once", :colspan => 2
          end
        end

        if check.checker
          # history rows
          history = (checker.checks[0..4]).to_a
          puts history.inspect
          history -= [check]
          drew_empty_cell = false
          history.each do |old_check|
            tr do
              td
              td do
                params_table(old_check.params - checker.params) # only show the non-standard params for old checks
              end
              check_run_cells(old_check)
              unless drew_empty_cell
                td :colspan => 2, :rowspan => history.size
              end
            end
          end
        end

      end
    end
  end

  def body_content

    magic_buttons
    h1 "sentry"
    checks_table
    br
    widget NewCheck

  end

end
