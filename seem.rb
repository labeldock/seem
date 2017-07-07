#!/usr/bin/ruby
class Seem
    def self.read
        Seem.new("hello seem",nil)
    end
    
    attr_reader :text, :path
    
    def initialize (itext="", ipath=nil)
        @text = itext
        @path = ipath
    end 
end