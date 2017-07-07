# Purpose
블럭 베이스 파일 텍스트 검색 및 수정

#Sudo (Concept)
```ruby
seemed = Seem.read("target.css","utf-8").seem(/(url\([^\)]*\))/, ['background-color:',';'], ['(\s+){','}']) do |seem|
    originalString = seem.matches[1]
    seem.matches[1] = 'none'
    puts "#{original} removed"
end

seemed.write("target.filtered.scss");
```