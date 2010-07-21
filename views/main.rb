class Main < Widget
  needs :checks
  def content
    head do
      title "Sentry"

      style <<-STYLE
/* reset.css from http://www.ejeliot.com/blog/85 */
body{padding:0;margin:0;font:13px Arial,Helvetica,Garuda,sans-serif;*font-size:small;*font:x-small;}
h1,h2,h3,h4,h5,h6,ul,li,em,strong,pre,code{padding:0;margin:0;line-height:1em;font-size:100%;font-weight:normal;font-style: normal;}
table{font-size:inherit;font:100%;}
ul{list-style:none;}
img{border:0;}
p{margin:1em 0;}

/* sentry main page */
body{ padding: 1em; }
h1 { font-size: 14pt; margin-top: .5em; margin-bottom: .25em; }
table { border-spacing: 0px 0px; border-collapse: collapse; }
td, th { border: 2px solid gray; }
td.param, th.param { border: 1px solid gray; }
td.param { width: 100%; }
td, th { padding: 2px; }
td.ok { color: green; }
td.failed { color: red; }
th { background-color: #EEE; text-align: left; }
      STYLE
    end

    h1 "sentry"

    table do
      tr do
        th { text "type" }
        th { text "params" }
        th { text "created" }
        th { text "outcome" }
        th { text "reason" }
      end
      @checks.each do |check|
        tr do
          td { text check.class.name }
          td do
            check.params.each_pair do |key, value|
              table :width => "100%" do
                tr do
                  th(:class => "param") { text key }
                  td(:class => "param") { text value }
                end
              end
            end
          end
          td { text check.created_at }
          td :class => check.outcome do
            text check.outcome
          end
          td { text check.reason }
        end
      end
    end
  end
end
