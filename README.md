# Purpose
Search and modify block base file text.
The source code is still under development.

# Concept
```ruby
seems = Seem.glob("*.css").match_select(Seem::STYLE_NAME :color, Seem::STYLE_BLOCK) do |seem|
    seem.body = "red"
end

seems.each do |seem|
    seem.write
end
```
