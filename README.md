# Purpose
Search and modify block base file text.
The source code is still under development.

# Concept
```ruby
seems = Seem.glob("*.css").each do |seem|
    # find
    seem.match Seem::STYLE_NAME :color, Seem::STYLE_BLOCK do |match|
        #replace
        match.replace_body = red
    end
    
    # write
    seem.write do |file|
        file.name = file.name.replace ".css", "replace.css"
    end
end
```