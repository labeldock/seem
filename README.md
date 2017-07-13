# Purpose
블럭 베이스 파일 텍스트 검색 및 수정

# Concept
```ruby
seems = Seem.glob("*.css").match_select(Seem::STYLE_NAME :color, Seem::STYLE_BLOCK) do |seem|
    seem.body = "red"
end

seems.each do |seem|
    seem.write
end
```
