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
h1 { font-size: 18pt; font-weight: bold; }
h2 { font-size: 14pt; }

div > h1, div > h2 {
  margin-top: 0;
}

/* styled tables */
table, td, th { vertical-align: top; }
tr { border: none; }
td, th { border: 2px solid gray; padding: 2px; }
th { background-color: #EEE; text-align: left; }

/* check table */
td.param, th.param { border: 1px solid gray; }
td.param { width: 100%; }
td.ok { color: green; }
td.failed { color: red; }
td.outcome { font-weight: bold; padding: 2px 4px; }
tr.divider td { border: none; background-color: white; height: 8px; }
td.divider { border: none; background-color: white; width: 8px; }

/* controls */
div.controls { float:right; margin: 0 2em 1em; padding: 1em; border: 2px solid blue; background: #EEEEFF; }
div.controls ul { list-style-type: none; }
div.controls li { display: inline; margin: .5em; }
div.controls form { display: inline; }
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

  include Environment

  def head_content
    super
    case environment
      when "development", "test"
        script :src => "/jquery-1.4.2.min.js"
      else
        script :src => "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
    end
  end

  def inline_scripts
    super
    # todo: allow :load or :ready as options, in normal ExternalRenderer for :jquery
    rendered_externals(:jquery_ready).each do |external|
      jquery :ready, external.text, external.options
    end
  end

  def button_form(label, action, method = "get")
    form :action => action, :method => method do
      input :type => :submit, :value => label
    end
  end

  def controls
    div :class => "controls" do
      h3 "magic buttons (don't touch!)"
      ul do
        if Cron.summon.job.nil?
          li do
            button_form("Start Cron", "/cron", "put")
          end
        else
          li do
            button_form("Stop Cron", "/cron", "delete")
          end
        end
        li do
          button_form("Run All Jobs", "/work")
        end
        li do
          button_form("Sample", "/sample")
        end
        li do
          button_form("Wipe DB", "/wipe")
        end
      end
    end
  end

  def settings
    h2 "settings"
    table do
      tr do
        td { widget NewCheck }
        td :class => "divider"
        td { widget Emails }
      end
    end
  end

  def body_content
    controls
    h1 "sentry"
    settings
    widget ChecksTable, :checks => @checks
  end

end
