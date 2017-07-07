# Purpose
블럭 베이스 파일 텍스트 검색 및 수정

# Concept
```ruby
seemed = Seem.glob("*.css").match_select('',Seem::Style :color, Seem::StyleBlock) do |seem|
    originalString = seem.matches[1]
    seem.matches[1] = 'none;'
    puts "#{original} removed"
end

seemed.write("target.filtered.scss");
```
