class NewCheck < Widget
# workaround, waiting for Erector 0.8.2
  def radio(name, attrs)
    element("input", attrs << {:type=>"radio"}) do
      text name
    end
  end
  
  def content
    h1 "new check"

    form :method => "post", :action => "/check" do
      table do
        tr do
          th "type"
          td do
            select :name => "check_type" do
              check_classes = [Fetch, Countdown, Send, NewTask]
              check_classes.each do |check_class|
                check_type = check_class.to_s
                option check_type, :value => check_type, :class => "check_type_selector"
              end

              check_classes.each do |check_class|
                check_type = check_class.to_s
                tr do
                  th "params"
                  td do
                    check_class.new.default_params.each_pair do |param_name, param_value|
                      table :class => "#{check_type}_params" do
                        tr do
                          th param_name
                          td do
                            input :name => "#{check_type}[#{param_name}]", :value => param_value
                          end
                        end
                      end
                    end
                  end
                end
              end

              tr do
                th "schedule"
                td do
                  radio "Just Once", :name=>"schedule", :value => "", :checked => true
                  radio "Every Minute", :type=>"radio", :name=>"schedule", :value => "1"
                  radio "Every Hour", :type=>"radio", :name=>"schedule", :value => "60"
                end
              end

              tr do
                th ""
                td do
                  input :type => "submit", :value => "Create"
                end
              end
            end
          end
        end
      end
    end
  end
end
