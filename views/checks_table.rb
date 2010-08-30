class ChecksTable < Widget
  needs :checks

  external :style, <<-STYLE
/* check table */
td.param, th.param { border: 1px solid gray; }
td.param { width: 100%; }
td.ok { color: green; }
td.failed { color: red; }
td.outcome { font-weight: bold; padding: 2px 4px; }
tr.divider td { border: none; background-color: white; height: 8px; }
td.divider { border: none; background-color: white; width: 8px; }
  STYLE

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

  def content
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
                drew_empty_cell = true
              end
            end
          end
        end

      end
    end
  end

end
