class Main < Widget
  needs :checks
  def content
    h1 "sentry"

    table do
      tr do
        th { text "type" }
        th { text "params" }
        th { text "outcome" }
        th {}
      end
      @checks.each do |check|
        tr do
          td { text check.class.name }
          td { text check.params.inspect }
          td { text check.outcome }
          td do
            input :type => "button", :value => "Run"
          end
        end
      end
    end
  end
end
