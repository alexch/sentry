class Emails < Widget
  def content
    div :class => "emails", :style => "vertical-align: top;" do
      h2 "emails"
      ul do
        Email.all.each do |email|
          li :style => "clear: right;" do
            form :action => "/email/#{email.id}", :method => "delete", :style => "float:right;" do
              input :type => :submit, :value => "[X]", :style => "background-color: #fed;"
            end
            puts email.inspect
            text email.address
          end
        end
      end

      br; br

      form :action => "/email", :method => "put", :style => "clear: right;" do
        input :type => :submit, :value => "Add", :style => "float: right;"
        input :type => :text, :name => "address"
      end
    end
  end
end
