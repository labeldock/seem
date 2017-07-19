# Purpose
Search and modify block base file text.
The source code is still under development.

# Concept
```ruby
seems = Seem.glob("*.css").each do |seem|
    # find
    seem.block :css do |match|
        #nested find
        match.block :css_name, :color do |match|
            match.replace do |inject|
                #replace
                inject.body = "red"
            end
        end
    end
    
    # write
    seem.write do |file|
        file.name = file.name.replace ".css", "replace.css"
    end
end
```