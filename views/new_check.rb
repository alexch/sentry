class NewCheck < Widget

  external :jquery_ready, <<-SCRIPT
var newCheckTable = $(".new_check_table");
var newCheckTypeSelector = $(".new_check_table select[name=check_type]");

function showSelectedType(selectElement) {
  log(this);
  selectElement = $(selectElement || this);
  selectedType = selectElement.val();
  log(selectedType);

  newCheckTable.find('tr.check_specific').hide();
  newCheckTable.find('tr.check_specific.' + selectedType).show();
}

// do it on load
showSelectedType(newCheckTypeSelector);

// do it on change
newCheckTypeSelector.change(function(event) {
  // annoying -- when this is called no option is selected
  setTimeout(function() {
    showSelectedType(newCheckTypeSelector);
  }, 1);
});

  SCRIPT

  # todo: move into Erector?
  def radio(name, attrs)
    label do
      input(attrs << {:type=>"radio"})
      text name
    end
  end

  def check_classes
    [Fetch, Countdown, Send, NewTask]
  end

  def check_type_selector_row
    tr do
      th "type"
      td do
        select :name => "check_type" do
          check_classes.each do |check_class|
            check_type = check_class.to_s
            option check_type, :value => check_type
          end
        end
      end
    end
  end

  def description_row(check_class)
    if check_class.description
      check_type = check_class.to_s # todo: put this into Check
      tr :class => ["check_specific", check_type] do
        th "description"
        td check_class.description
      end
    end
  end

  def params_row(check_class)
    check_type = check_class.to_s # todo: put this into Check
    tr :class => ["check_specific", check_type] do
      th "params"
      td do
        table :class => "#{check_type}_params" do
          check_class.new.default_params.each_pair do |param_name, param_value|
            tr do
              th param_name, :class => "param"
              td :class => "param" do
                input :name => "#{check_type}[#{param_name}]", :value => param_value
              end
            end
          end
        end
      end
    end
  end

  def schedule_row
    tr do
      th "schedule"
      td do
        ul do
          li { radio "Just Once", :name=>"schedule", :value => "", :checked => true }
          li { radio "Every Minute", :type=>"radio", :name=>"schedule", :value => "1" }
          li { radio "Every Hour", :type=>"radio", :name=>"schedule", :value => "60" }
        end
      end
    end
  end

  def submit_row
    tr do
      th ""
      td do
        input :type => "submit", :value => "Create"
      end
    end
  end

  def content

    div :class => "new_check" do
      h2 "new check"

      form :method => "post", :action => "/check" do
        table :class => "new_check_table" do
          check_type_selector_row
          check_classes.each do |check_class|
            description_row(check_class)
            params_row(check_class)
          end
          schedule_row
          submit_row
        end
      end
    end
  end
end
